# frozen_string_literal: true

module API
  module Entities
    class MergeRequestBasic < IssuableEntity
      # Deprecated in favour of merge_user
      expose :merged_by, using: ::API::Entities::UserBasic do |merge_request, _options|
        merge_request.metrics&.merged_by
      end
      expose :merge_user, using: ::API::Entities::UserBasic do |merge_request|
        merge_request.metrics&.merged_by || merge_request.merge_user
      end
      expose :merged_at,
        documentation: { type: 'DateTime', example: '2022-01-31T15:10:45.080Z' } do |merge_request, _options|
        merge_request.metrics&.merged_at
      end
      expose :closed_by, using: ::API::Entities::UserBasic do |merge_request, _options|
        merge_request.metrics&.latest_closed_by
      end
      expose :closed_at,
        documentation: { type: 'DateTime', example: '2022-01-31T15:10:45.080Z' } do |merge_request, _options|
        merge_request.metrics&.latest_closed_at
      end
      expose :title_html, documentation: { type: 'String' }, if: ->(_, options) { options[:render_html] } do |entity|
        MarkupHelper.markdown_field(entity, :title)
      end
      expose :description_html, documentation: { type: 'String' }, if: ->(_, options) {
        options[:render_html]
      } do |entity|
        MarkupHelper.markdown_field(entity, :description)
      end
      expose :target_branch, documentation: { type: 'String' }
      expose :source_branch, documentation: { type: 'String' }
      expose(:user_notes_count, documentation: { type: 'Integer' }) do |merge_request, options|
        issuable_metadata.user_notes_count
      end
      expose(:upvotes, documentation: { type: 'Integer' }) do |merge_request, options|
        issuable_metadata.upvotes
      end
      expose(:downvotes, documentation: { type: 'Integer' }) do |merge_request, options|
        issuable_metadata.downvotes
      end

      expose :author, using: ::API::Entities::UserBasic
      expose :assignees, using: ::API::Entities::UserBasic
      expose :assignee, using: ::API::Entities::UserBasic
      expose :reviewers, using: ::API::Entities::UserBasic
      expose :source_project_id, documentation: { type: 'Integer' }
      expose :target_project_id, documentation: { type: 'Integer' }
      expose :labels, documentation: { type: 'String', is_array: true } do |merge_request, options|
        if options[:with_labels_details]
          ::API::Entities::LabelBasic.represent(merge_request.labels.sort_by(&:title))
        else
          merge_request.labels.map(&:title).sort
        end
      end
      expose :draft?, as: :draft, documentation: { type: 'Boolean' }
      expose :imported?, as: :imported, documentation: { type: 'Boolean' }
      expose :imported_from, documentation: { type: 'String', example: 'bitbucket' }

      # [Deprecated]  see draft
      #
      expose :draft?, as: :work_in_progress, documentation: { type: 'Boolean' }
      expose :milestone, using: ::API::Entities::Milestone
      expose :merge_when_pipeline_succeeds, documentation: { type: 'Boolean' }

      # Ideally we should deprecate `MergeRequest#merge_status` exposure and
      # use `MergeRequest#mergeable?` instead (boolean).
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/42344 for more
      # information.
      #
      # For list endpoints, we skip the recheck by default, since it's expensive
      expose :merge_status, documentation: { type: 'String', example: 'unchecked' } do |merge_request, options|
        if !options[:skip_merge_status_recheck] && can_check_mergeability?(merge_request.project)
          merge_request.check_mergeability(async: true)
        end

        merge_request.public_merge_status
      end
      expose :detailed_merge_status, documentation: { type: 'String', example: 'mergeable' }

      expose :merge_after,
        documentation: { type: 'DateTime', example: '2022-01-31T15:10:45.080Z' } do |merge_request, _options|
        merge_request.merge_schedule&.merge_after
      end

      expose :diff_head_sha, as: :sha, documentation: { type: 'String', example: '1234abcd' }
      expose :merge_commit_sha, documentation: { type: 'String', example: '1234abcd' }
      expose :squash_commit_sha, documentation: { type: 'String', example: '1234abcd' }
      expose :discussion_locked, documentation: { type: 'Boolean' }
      expose :should_remove_source_branch?, as: :should_remove_source_branch, documentation: { type: 'Boolean' }
      expose :force_remove_source_branch?, as: :force_remove_source_branch, documentation: { type: 'Boolean' }
      expose :prepared_at, documentation: { type: 'DateTime', example: '2022-01-31T15:10:45.080Z' }

      with_options if: ->(merge_request, _) { merge_request.for_fork? } do
        expose :allow_collaboration, documentation: { type: 'Boolean' }
        # Deprecated
        expose :allow_collaboration, as: :allow_maintainer_to_push, documentation: { type: 'Boolean' }
      end

      # reference is deprecated in favour of references
      # Introduced [Gitlab 12.6](https://gitlab.com/gitlab-org/gitlab/merge_requests/20354)
      expose :reference, documentation: { type: 'String', example: '!1' } do |merge_request, options|
        merge_request.to_reference(options[:project])
      end

      expose :references, documentation: { type: 'Hash' }, with: IssuableReferences do |merge_request|
        merge_request
      end

      expose :web_url,
        documentation: {
          type: 'String',
          example: 'https://gitlab.example.com/my-group/my-project/-/merge_requests/1'
        } do |merge_request|
        Gitlab::UrlBuilder.build(merge_request)
      end

      expose :time_stats, using: ::API::Entities::IssuableTimeStats do |merge_request|
        merge_request
      end

      expose :squash, documentation: { type: 'Boolean' }
      expose :squash_on_merge?, as: :squash_on_merge, documentation: { type: 'Boolean' }
      expose :task_completion_status,
        using: ::API::Entities::TaskCompletionStatus,
        documentation: { type: 'Entities::TaskCompletionStatus' }

      # #cannot_be_merged? is generally indicative of conflicts, and is set via
      #   MergeRequests::MergeabilityCheckService. However, it can also indicate
      #   that either #has_no_commits? or #branch_missing? are true.
      #
      expose :cannot_be_merged?, as: :has_conflicts, documentation: { type: 'Boolean' }
      expose :mergeable_discussions_state?, as: :blocking_discussions_resolved, documentation: { type: 'Boolean' }

      private

      def detailed_merge_status
        ::MergeRequests::Mergeability::DetailedMergeStatusService.new(merge_request: object).execute
      end

      def can_check_mergeability?(project)
        Ability.allowed?(options[:current_user], :update_merge_request, project)
      end
    end
  end
end

API::Entities::MergeRequestBasic.prepend_mod_with('API::Entities::MergeRequestBasic', with_descendants: true)
