# frozen_string_literal: true

module API
  module Entities
    class MergeRequestBasic < IssuableEntity
      expose :merged_by, using: Entities::UserBasic do |merge_request, _options|
        merge_request.metrics&.merged_by
      end
      expose :merged_at do |merge_request, _options|
        merge_request.metrics&.merged_at
      end
      expose :closed_by, using: Entities::UserBasic do |merge_request, _options|
        merge_request.metrics&.latest_closed_by
      end
      expose :closed_at do |merge_request, _options|
        merge_request.metrics&.latest_closed_at
      end
      expose :title_html, if: -> (_, options) { options[:render_html] } do |entity|
        MarkupHelper.markdown_field(entity, :title)
      end
      expose :description_html, if: -> (_, options) { options[:render_html] } do |entity|
        MarkupHelper.markdown_field(entity, :description)
      end
      expose :target_branch, :source_branch
      expose(:user_notes_count) { |merge_request, options| issuable_metadata.user_notes_count }
      expose(:upvotes)          { |merge_request, options| issuable_metadata.upvotes }
      expose(:downvotes)        { |merge_request, options| issuable_metadata.downvotes }

      expose :author, :assignees, :assignee, using: Entities::UserBasic
      expose :reviewers, using: Entities::UserBasic
      expose :source_project_id, :target_project_id
      expose :labels do |merge_request, options|
        if options[:with_labels_details]
          ::API::Entities::LabelBasic.represent(merge_request.labels.sort_by(&:title))
        else
          merge_request.labels.map(&:title).sort
        end
      end
      expose :draft?, as: :draft

      # [Deprecated]  see draft
      #
      expose :draft?, as: :work_in_progress
      expose :milestone, using: Entities::Milestone
      expose :merge_when_pipeline_succeeds

      # Ideally we should deprecate `MergeRequest#merge_status` exposure and
      # use `MergeRequest#mergeable?` instead (boolean).
      # See https://gitlab.com/gitlab-org/gitlab-foss/issues/42344 for more
      # information.
      #
      # For list endpoints, we skip the recheck by default, since it's expensive
      expose :merge_status do |merge_request, options|
        merge_request.check_mergeability(async: true) unless options[:skip_merge_status_recheck]
        merge_request.public_merge_status
      end
      expose :diff_head_sha, as: :sha
      expose :merge_commit_sha
      expose :squash_commit_sha
      expose :discussion_locked
      expose :should_remove_source_branch?, as: :should_remove_source_branch
      expose :force_remove_source_branch?, as: :force_remove_source_branch

      with_options if: -> (merge_request, _) { merge_request.for_fork? } do
        expose :allow_collaboration
        # Deprecated
        expose :allow_collaboration, as: :allow_maintainer_to_push
      end

      # reference is deprecated in favour of references
      # Introduced [Gitlab 12.6](https://gitlab.com/gitlab-org/gitlab/merge_requests/20354)
      expose :reference do |merge_request, options|
        merge_request.to_reference(options[:project])
      end

      expose :references, with: IssuableReferences do |merge_request|
        merge_request
      end

      expose :web_url do |merge_request|
        Gitlab::UrlBuilder.build(merge_request)
      end

      expose :time_stats, using: 'API::Entities::IssuableTimeStats' do |merge_request|
        merge_request
      end

      expose :squash
      expose :task_completion_status
      expose :cannot_be_merged?, as: :has_conflicts
      expose :mergeable_discussions_state?, as: :blocking_discussions_resolved
    end
  end
end

API::Entities::MergeRequestBasic.prepend_mod_with('API::Entities::MergeRequestBasic', with_descendants: true)
