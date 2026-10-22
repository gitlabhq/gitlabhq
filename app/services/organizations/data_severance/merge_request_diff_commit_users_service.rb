# frozen_string_literal: true

module Organizations
  module DataSeverance
    class MergeRequestDiffCommitUsersService
      BATCH_SIZE = 1000

      def initialize(group:, old_organization:, new_organization:)
        @group = group
        @old_organization = old_organization
        @new_organization = new_organization
      end

      def execute(cursor: nil)
        # rubocop: disable CodeReuse/ActiveRecord -- cursor-based outer iteration
        projects_relation.where('id > ?', cursor.to_i).each_batch(of: 1) do |project_batch|
          # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- bounded to 1 row by each_batch(of: 1)
          project_ids = project_batch.pluck(:id)
          # rubocop: enable Database/AvoidUsingPluckWithoutLimit
          process_project_ids(project_ids)
          yield project_ids.max if block_given?
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end

      private

      attr_reader :group, :old_organization, :new_organization

      def old_org_id
        Integer(old_organization.id)
      end

      def new_org_id
        Integer(new_organization.id)
      end

      def projects_relation
        Project.in_namespace(group.self_and_descendant_ids(skope: Namespace))
      end

      def process_project_ids(project_ids)
        # rubocop: disable CodeReuse/ActiveRecord -- direct AR query required to scope the inner batch
        MergeRequest::CommitsMetadata.where(project_id: project_ids)
          .each_batch(of: BATCH_SIZE) do |meta_batch|
            clone_all_referenced_users(meta_batch)
            update_commits_metadata(meta_batch, project_ids)
            sleep 0.01
          end
        # rubocop: enable CodeReuse/ActiveRecord
      end

      # Single-scan unnest of both author columns for the batch's commits.
      # Used as the scope for both the INSERT and the UPDATE JOIN.
      def referenced_user_ids_sql(meta_batch)
        meta_batch.select("DISTINCT unnest(ARRAY[commit_author_id, committer_id])").to_sql
      end

      # The new_org row matching old_user's (name, email), treating NULLs as equal.
      # name or email may be NULL, which `=` and the unique index never match.
      # One UNION ALL branch per NULL case keeps each lookup on the
      # (organization_id, name, email) index, which an OR would not.
      def new_org_user_id_sql(old_user)
        <<~SQL
          SELECT n.id FROM merge_request_diff_commit_users n
          WHERE  n.organization_id = #{new_org_id}
            AND  n.name = #{old_user}.name AND n.email = #{old_user}.email
          UNION ALL
          SELECT n.id FROM merge_request_diff_commit_users n
          WHERE  n.organization_id = #{new_org_id}
            AND  #{old_user}.name IS NULL AND n.name IS NULL AND n.email = #{old_user}.email
          UNION ALL
          SELECT n.id FROM merge_request_diff_commit_users n
          WHERE  n.organization_id = #{new_org_id}
            AND  #{old_user}.email IS NULL AND n.email IS NULL AND n.name = #{old_user}.name
          LIMIT  1
        SQL
      end

      # Create new_org rows for every old_org user referenced by the
      # batch's commits. NOT EXISTS skips users already in new_org, including
      # NULL name/email rows that ON CONFLICT can't detect.
      def clone_all_referenced_users(meta_batch)
        ApplicationRecord.connection.execute(Arel.sql(<<~SQL))
          INSERT INTO merge_request_diff_commit_users (name, email, organization_id)
          SELECT DISTINCT u.name, u.email, #{new_org_id}
          FROM   merge_request_diff_commit_users u
          WHERE  u.organization_id = #{old_org_id}
            AND  u.id IN (#{referenced_user_ids_sql(meta_batch)})
            AND  NOT EXISTS (#{new_org_user_id_sql('u')})
          ON CONFLICT (organization_id, name, email) DO NOTHING
        SQL
      end

      # Repoint commit_author_id and committer_id in
      # merge_request_commits_metadata for the batch's rows. Both columns are
      # set in one statement so each row is rewritten once, not twice.
      def update_commits_metadata(meta_batch, project_ids)
        batch_cte_sql = meta_batch.select(:id, :commit_author_id, :committer_id).to_sql

        ApplicationRecord.connection.execute(Arel.sql(<<~SQL))
          WITH batch AS MATERIALIZED (
            #{batch_cte_sql}
          )
          UPDATE merge_request_commits_metadata m
          SET    commit_author_id = COALESCE(new_a.id, m.commit_author_id),
                 committer_id     = COALESCE(new_c.id, m.committer_id)
          FROM   batch b
          LEFT JOIN merge_request_diff_commit_users old_a
                 ON  old_a.id = b.commit_author_id AND old_a.organization_id = #{old_org_id}
          LEFT JOIN LATERAL (#{new_org_user_id_sql('old_a')}) new_a ON true
          LEFT JOIN merge_request_diff_commit_users old_c
                 ON  old_c.id = b.committer_id AND old_c.organization_id = #{old_org_id}
          LEFT JOIN LATERAL (#{new_org_user_id_sql('old_c')}) new_c ON true

          WHERE  m.id = b.id
            AND  m.project_id IN (#{sanitize_project_ids(project_ids)})
            AND  (new_a.id IS NOT NULL OR new_c.id IS NOT NULL)
        SQL
      end

      def sanitize_project_ids(project_ids)
        project_ids.map { |id| Integer(id) }.join(', ')
      end
    end
  end
end
