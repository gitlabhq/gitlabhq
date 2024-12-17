# frozen_string_literal: true

module Gitlab
  module Import
    module MergeRequestHelpers
      include DatabaseHelpers

      # @param attributes [Hash]
      # @return MergeRequest::Metrics
      def create_merge_request_metrics(attributes)
        metric = MergeRequest::Metrics.find_or_initialize_by(merge_request: merge_request) # rubocop: disable CodeReuse/ActiveRecord -- no need to move this to ActiveRecord model
        metric.update(attributes)
        metric
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def create_merge_request_without_hooks(project, attributes, iid)
        # This work must be wrapped in a transaction as otherwise we can leave
        # behind incomplete data in the event of an error. This can then lead
        # to duplicate key errors when jobs are retried.
        MergeRequest.transaction do
          # When creating merge requests there are a lot of hooks that may
          # run, for many different reasons. Many of these hooks (e.g. the
          # ones used for rendering Markdown) are completely unnecessary and
          # may even lead to transaction timeouts.
          #
          # To ensure importing pull requests has a minimal impact and can
          # complete in a reasonable time we bypass all the hooks by inserting
          # the row and then retrieving it. We then only perform the
          # additional work that is strictly necessary.
          merge_request_id = insert_and_return_id(attributes, project.merge_requests)

          merge_request = project.merge_requests.reset.find(merge_request_id)

          [merge_request, false]
        end
      rescue ActiveRecord::InvalidForeignKey
        # It's possible the project has been deleted since scheduling this
        # job. In this case we'll just skip creating the merge request.
        []
      rescue ActiveRecord::RecordNotUnique
        # It's possible we previously created the MR, but failed when updating
        # the Git data. In this case we'll just continue working on the
        # existing row.
        [project.merge_requests.find_by(iid: iid), true]
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def insert_or_replace_git_data(merge_request, source_branch_sha, target_branch_sha, already_exists = false)
        # These fields are set so we can create the correct merge request
        # diffs.
        merge_request.source_branch_sha = source_branch_sha
        merge_request.target_branch_sha = target_branch_sha

        merge_request.keep_around_commit

        # We force to recreate all diffs to replace all existing data
        # We use `.all` as otherwise `dependent: :nullify` (the default)
        # takes an effect
        merge_request.merge_request_diffs.all.delete_all if already_exists

        # MR diffs normally use an "after_save" hook to pull data from Git.
        # All of this happens in the transaction started by calling
        # create/save/etc. This in turn can lead to these transactions being
        # held open for much longer than necessary. To work around this we
        # first save the diff, then populate it.
        diff = merge_request.merge_request_diffs.build
        diff.importing = true
        diff.save
        diff.save_git_content
        diff.set_as_latest_diff
      end

      def insert_merge_request_reviewers(merge_request, reviewers)
        return unless reviewers.present?

        rows = reviewers.map { |reviewer_id| { merge_request_id: merge_request.id, user_id: reviewer_id } }
        MergeRequestReviewer.insert_all(rows)
      end

      def create_approval!(project_id, merge_request_id, user_id, submitted_at)
        approval = Approval.create(
          merge_request_id: merge_request_id,
          user_id: user_id,
          created_at: submitted_at,
          updated_at: submitted_at,
          importing: true
        )

        return unless approval.persisted?

        note = add_approval_system_note!(project_id, merge_request_id, user_id, submitted_at)

        [approval, note]
      end

      def add_approval_system_note!(project_id, merge_request_id, user_id, submitted_at)
        attributes = {
          importing: true,
          noteable_id: merge_request_id,
          noteable_type: 'MergeRequest',
          project_id: project_id,
          author_id: user_id,
          note: 'approved this merge request',
          system: true,
          system_note_metadata: SystemNoteMetadata.new(action: 'approved'),
          created_at: submitted_at,
          updated_at: submitted_at
        }

        Note.create!(attributes)
      end

      def create_reviewer!(merge_request_id, user_id, submitted_at)
        ::MergeRequestReviewer.create!(
          merge_request_id: merge_request_id,
          user_id: user_id,
          state: ::MergeRequestReviewer.states['reviewed'],
          created_at: submitted_at
        )
      rescue ActiveRecord::RecordNotUnique
        # multiple reviews from single person could make a SQL concurrency issue here
        nil
      end
    end
  end
end
