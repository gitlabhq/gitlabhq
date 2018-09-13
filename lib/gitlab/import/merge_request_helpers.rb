# frozen_string_literal: true

module Gitlab
  module Import
    module MergeRequestHelpers
      include DatabaseHelpers

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

          merge_request = project.merge_requests.find(merge_request_id)

          # We use .insert_and_return_id which effectively disables all callbacks.
          # Trigger iid logic here to make sure we track internal id values consistently.
          merge_request.ensure_target_project_iid!

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

      # rubocop: disable CodeReuse/ActiveRecord
      def insert_or_replace_git_data(merge_request, source_branch_sha, target_branch_sha, already_exists = false)
        # These fields are set so we can create the correct merge request
        # diffs.
        merge_request.source_branch_sha = source_branch_sha
        merge_request.target_branch_sha = target_branch_sha

        merge_request.keep_around_commit

        # MR diffs normally use an "after_save" hook to pull data from Git.
        # All of this happens in the transaction started by calling
        # create/save/etc. This in turn can lead to these transactions being
        # held open for much longer than necessary. To work around this we
        # first save the diff, then populate it.
        diff =
          if already_exists
            merge_request.merge_request_diffs.take ||
              merge_request.merge_request_diffs.build
          else
            merge_request.merge_request_diffs.build
          end

        diff.importing = true
        diff.save
        diff.save_git_content
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
