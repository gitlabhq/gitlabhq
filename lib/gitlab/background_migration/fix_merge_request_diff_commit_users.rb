# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for fixing merge_request_diff_commit rows that don't
    # have committer/author details due to
    # https://gitlab.com/gitlab-org/gitlab/-/issues/344080.
    #
    # This migration acts on a single project and corrects its data. Because
    # this process needs Git/Gitaly access, and duplicating all that code is far
    # too much, this migration relies on global models such as Project,
    # MergeRequest, etc.
    # rubocop: disable Metrics/ClassLength
    class FixMergeRequestDiffCommitUsers
      BATCH_SIZE = 100

      def initialize
        @commits = {}
        @users = {}
      end

      def perform(project_id)
        if (project = ::Project.find_by_id(project_id))
          process(project)
        end

        ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'FixMergeRequestDiffCommitUsers',
          [project_id]
        )

        schedule_next_job
      end

      def process(project)
        # Loading everything using one big query may result in timeouts (e.g.
        # for projects the size of gitlab-org/gitlab). So instead we query
        # data on a per merge request basis.
        project.merge_requests.each_batch(column: :iid) do |mrs|
          mrs.ids.each do |mr_id|
            each_row_to_check(mr_id) do |commit|
              update_commit(project, commit)
            end
          end
        end
      end

      def each_row_to_check(merge_request_id, &block)
        columns = %w[merge_request_diff_id relative_order].map do |col|
          Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: col,
            order_expression: MergeRequestDiffCommit.arel_table[col.to_sym].asc,
            nullable: :not_nullable,
            distinct: false
          )
        end

        order = Pagination::Keyset::Order.build(columns)
        scope = MergeRequestDiffCommit
          .joins(:merge_request_diff)
          .where(merge_request_diffs: { merge_request_id: merge_request_id })
          .where('commit_author_id IS NULL OR committer_id IS NULL')
          .order(order)

        Pagination::Keyset::Iterator
          .new(scope: scope, use_union_optimization: true)
          .each_batch(of: BATCH_SIZE) do |rows|
            rows
              .select([
                :merge_request_diff_id,
                :relative_order,
                :sha,
                :committer_id,
                :commit_author_id
              ])
              .each(&block)
          end
      end

      # rubocop: disable Metrics/AbcSize
      def update_commit(project, row)
        commit = find_commit(project, row.sha)
        updates = []

        unless row.commit_author_id
          author_id = find_or_create_user(commit, :author_name, :author_email)

          updates << [arel_table[:commit_author_id], author_id] if author_id
        end

        unless row.committer_id
          committer_id =
            find_or_create_user(commit, :committer_name, :committer_email)

          updates << [arel_table[:committer_id], committer_id] if committer_id
        end

        return if updates.empty?

        update = Arel::UpdateManager
          .new
          .table(MergeRequestDiffCommit.arel_table)
          .where(matches_row(row))
          .set(updates)
          .to_sql

        MergeRequestDiffCommit.connection.execute(update)
      end
      # rubocop: enable Metrics/AbcSize

      def schedule_next_job
        job = Database::BackgroundMigrationJob
          .for_migration_class('FixMergeRequestDiffCommitUsers')
          .pending
          .first

        return unless job

        BackgroundMigrationWorker.perform_in(
          2.minutes,
          'FixMergeRequestDiffCommitUsers',
          job.arguments
        )
      end

      def find_commit(project, sha)
        @commits[sha] ||= (project.commit(sha)&.to_hash || {})
      end

      def find_or_create_user(commit, name_field, email_field)
        name = commit[name_field]
        email = commit[email_field]

        return unless name && email

        @users[[name, email]] ||=
          MergeRequest::DiffCommitUser.find_or_create(name, email).id
      end

      def matches_row(row)
        primary_key = Arel::Nodes::Grouping
          .new([arel_table[:merge_request_diff_id], arel_table[:relative_order]])

        primary_val = Arel::Nodes::Grouping
          .new([row.merge_request_diff_id, row.relative_order])

        primary_key.eq(primary_val)
      end

      def arel_table
        MergeRequestDiffCommit.arel_table
      end
    end
    # rubocop: enable Metrics/ClassLength
  end
end
