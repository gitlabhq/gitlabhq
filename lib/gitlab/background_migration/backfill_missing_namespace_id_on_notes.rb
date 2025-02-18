# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMissingNamespaceIdOnNotes < BatchedMigrationJob
      operation_name :backfill_missing_namespace_id_on_notes
      feature_category :code_review_workflow

      def perform
        each_sub_batch do |sub_batch|
          Gitlab::Database.allow_cross_joins_across_databases(
            url: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163687'
          ) do
            connection.execute(build_query(sub_batch))
          end
        end
      end

      private

      # rubocop:disable Layout/LineLength -- SQL!
      # rubocop:disable Metrics/MethodLength -- I do what I want
      def build_query(scope)
        records_query = scope.where(namespace_id: nil).select("
          id,
          (
            coalesce(
            (case
              when exists (select 1 from projects where id = notes.project_id) then (select namespace_id from projects where id = notes.project_id)
              when noteable_type  = 'AlertManagement::Alert' then (select namespace_id from projects where id = (select project_id from alert_management_alerts where noteable_id = notes.id limit 1) limit 1)
              when noteable_type  = 'MergeRequest' then (select namespace_id from projects where id = (select project_id from merge_requests where noteable_id = notes.id limit 1) limit 1)
              when noteable_type  = 'Vulnerability' then (select namespace_id from projects where id = (select project_id from vulnerabilities where noteable_id = notes.id limit 1) limit 1)
              -- These 2 need to pull namespace_id from the noteable
              when noteable_type  = 'DesignManagement::Design' then (select namespace_id from design_management_designs where id = notes.noteable_id limit 1)
              when noteable_type  = 'Issue' then (select namespace_id from issues where id = notes.noteable_id limit 1)
              -- Epics pull in group_id
              when noteable_type  = 'Epic' then (select group_id from epics where id = notes.noteable_id limit 1)
              -- Snippets pull from author
              when noteable_type  = 'Snippet' then (select id from namespaces where owner_id = (select author_id from notes where id = notes.id limit 1) limit 1)
              -- Commits pull namespace_id from the project of the note
              when noteable_type  = 'Commit' then (select namespace_id from projects where id = notes.project_id limit 1)
            else
              -1
            end
          ), -1)) as namespace_id_to_set
        ")

        <<~SQL
        with records AS (
          #{records_query.to_sql}
        ), updated_rows as (
          -- updating records with the located namespace_id_to_set value
          update notes set namespace_id = namespace_id_to_set from records where records.id=notes.id and namespace_id_to_set <> -1
        ), deleted_rows as (
          -- deleting the records where we couldn't find the namespace id
          delete from notes where id IN (select id from records where namespace_id_to_set = -1)
        )
        select 1
        SQL
      end
      # rubocop:enable Layout/LineLength
      # rubocop:enable Metrics/MethodLength

      def backfillable?(note)
        note.noteable_type.present?
      end

      def extract_namespace_id(note)
        # Attempt to find namespace_id from the project first.
        #
        if note.project_id
          project = Project.find_by_id(note.project_id)

          return project.namespace_id if project
        end

        # We have to load the noteable here because we don't have access to the
        #   usual ActiveRecord relationships to do it for us.
        #
        noteable = note.noteable_type.constantize.find(note.noteable_id)

        case note.noteable_type
        when "AlertManagement::Alert", "Commit", "MergeRequest", "Vulnerability"
          noteable.project.namespace_id
        when "DesignManagement::Design", "Epic", "Issue"
          noteable.namespace_id
        when "Snippet"
          noteable.author.namespace_id
        end
      end
    end
  end
end
