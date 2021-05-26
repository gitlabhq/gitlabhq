# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module MergeRequestActivityUniqueCounter
      MR_DIFFS_ACTION = 'i_code_review_mr_diffs'
      MR_DIFFS_SINGLE_FILE_ACTION = 'i_code_review_mr_single_file_diffs'
      MR_DIFFS_USER_SINGLE_FILE_ACTION = 'i_code_review_user_single_file_diffs'
      MR_CREATE_ACTION = 'i_code_review_user_create_mr'
      MR_CLOSE_ACTION = 'i_code_review_user_close_mr'
      MR_REOPEN_ACTION = 'i_code_review_user_reopen_mr'
      MR_MERGE_ACTION = 'i_code_review_user_merge_mr'
      MR_APPROVE_ACTION = 'i_code_review_user_approve_mr'
      MR_UNAPPROVE_ACTION = 'i_code_review_user_unapprove_mr'
      MR_CREATE_COMMENT_ACTION = 'i_code_review_user_create_mr_comment'
      MR_EDIT_COMMENT_ACTION = 'i_code_review_user_edit_mr_comment'
      MR_REMOVE_COMMENT_ACTION = 'i_code_review_user_remove_mr_comment'
      MR_CREATE_REVIEW_NOTE_ACTION = 'i_code_review_user_create_review_note'
      MR_PUBLISH_REVIEW_ACTION = 'i_code_review_user_publish_review'
      MR_CREATE_MULTILINE_COMMENT_ACTION = 'i_code_review_user_create_multiline_mr_comment'
      MR_EDIT_MULTILINE_COMMENT_ACTION = 'i_code_review_user_edit_multiline_mr_comment'
      MR_REMOVE_MULTILINE_COMMENT_ACTION = 'i_code_review_user_remove_multiline_mr_comment'
      MR_ADD_SUGGESTION_ACTION = 'i_code_review_user_add_suggestion'
      MR_APPLY_SUGGESTION_ACTION = 'i_code_review_user_apply_suggestion'
      MR_MARKED_AS_DRAFT_ACTION = 'i_code_review_user_marked_as_draft'
      MR_UNMARKED_AS_DRAFT_ACTION = 'i_code_review_user_unmarked_as_draft'
      MR_RESOLVE_THREAD_ACTION = 'i_code_review_user_resolve_thread'
      MR_UNRESOLVE_THREAD_ACTION = 'i_code_review_user_unresolve_thread'
      MR_ASSIGNED_USERS_ACTION = 'i_code_review_user_assigned'
      MR_REVIEW_REQUESTED_USERS_ACTION = 'i_code_review_user_review_requested'
      MR_TASK_ITEM_STATUS_CHANGED_ACTION = 'i_code_review_user_toggled_task_item_status'
      MR_APPROVAL_RULE_ADDED_USERS_ACTION = 'i_code_review_user_approval_rule_added'
      MR_APPROVAL_RULE_EDITED_USERS_ACTION = 'i_code_review_user_approval_rule_edited'
      MR_APPROVAL_RULE_DELETED_USERS_ACTION = 'i_code_review_user_approval_rule_deleted'
      MR_EDIT_MR_TITLE_ACTION = 'i_code_review_edit_mr_title'
      MR_EDIT_MR_DESC_ACTION = 'i_code_review_edit_mr_desc'
      MR_CREATE_FROM_ISSUE_ACTION = 'i_code_review_user_create_mr_from_issue'
      MR_DISCUSSION_LOCKED_ACTION = 'i_code_review_user_mr_discussion_locked'
      MR_DISCUSSION_UNLOCKED_ACTION = 'i_code_review_user_mr_discussion_unlocked'
      MR_TIME_ESTIMATE_CHANGED_ACTION = 'i_code_review_user_time_estimate_changed'
      MR_TIME_SPENT_CHANGED_ACTION = 'i_code_review_user_time_spent_changed'
      MR_ASSIGNEES_CHANGED_ACTION = 'i_code_review_user_assignees_changed'
      MR_REVIEWERS_CHANGED_ACTION = 'i_code_review_user_reviewers_changed'
      MR_INCLUDING_CI_CONFIG_ACTION = 'o_pipeline_authoring_unique_users_pushing_mr_ciconfigfile'
      MR_MILESTONE_CHANGED_ACTION = 'i_code_review_user_milestone_changed'
      MR_LABELS_CHANGED_ACTION = 'i_code_review_user_labels_changed'
      MR_LOAD_CONFLICT_UI_ACTION = 'i_code_review_user_load_conflict_ui'
      MR_RESOLVE_CONFLICT_ACTION = 'i_code_review_user_resolve_conflict'

      class << self
        def track_mr_diffs_action(merge_request:)
          track_unique_action_by_merge_request(MR_DIFFS_ACTION, merge_request)
        end

        def track_mr_diffs_single_file_action(merge_request:, user:)
          track_unique_action_by_merge_request(MR_DIFFS_SINGLE_FILE_ACTION, merge_request)
          track_unique_action_by_user(MR_DIFFS_USER_SINGLE_FILE_ACTION, user)
        end

        def track_create_mr_action(user:)
          track_unique_action_by_user(MR_CREATE_ACTION, user)
        end

        def track_close_mr_action(user:)
          track_unique_action_by_user(MR_CLOSE_ACTION, user)
        end

        def track_merge_mr_action(user:)
          track_unique_action_by_user(MR_MERGE_ACTION, user)
        end

        def track_reopen_mr_action(user:)
          track_unique_action_by_user(MR_REOPEN_ACTION, user)
        end

        def track_approve_mr_action(user:)
          track_unique_action_by_user(MR_APPROVE_ACTION, user)
        end

        def track_unapprove_mr_action(user:)
          track_unique_action_by_user(MR_UNAPPROVE_ACTION, user)
        end

        def track_resolve_thread_action(user:)
          track_unique_action_by_user(MR_RESOLVE_THREAD_ACTION, user)
        end

        def track_unresolve_thread_action(user:)
          track_unique_action_by_user(MR_UNRESOLVE_THREAD_ACTION, user)
        end

        def track_create_comment_action(note:)
          track_unique_action_by_user(MR_CREATE_COMMENT_ACTION, note.author)
          track_multiline_unique_action(MR_CREATE_MULTILINE_COMMENT_ACTION, note)
        end

        def track_edit_comment_action(note:)
          track_unique_action_by_user(MR_EDIT_COMMENT_ACTION, note.author)
          track_multiline_unique_action(MR_EDIT_MULTILINE_COMMENT_ACTION, note)
        end

        def track_remove_comment_action(note:)
          track_unique_action_by_user(MR_REMOVE_COMMENT_ACTION, note.author)
          track_multiline_unique_action(MR_REMOVE_MULTILINE_COMMENT_ACTION, note)
        end

        def track_create_review_note_action(user:)
          track_unique_action_by_user(MR_CREATE_REVIEW_NOTE_ACTION, user)
        end

        def track_publish_review_action(user:)
          track_unique_action_by_user(MR_PUBLISH_REVIEW_ACTION, user)
        end

        def track_add_suggestion_action(user:)
          track_unique_action_by_user(MR_ADD_SUGGESTION_ACTION, user)
        end

        def track_marked_as_draft_action(user:)
          track_unique_action_by_user(MR_MARKED_AS_DRAFT_ACTION, user)
        end

        def track_unmarked_as_draft_action(user:)
          track_unique_action_by_user(MR_UNMARKED_AS_DRAFT_ACTION, user)
        end

        def track_apply_suggestion_action(user:)
          track_unique_action_by_user(MR_APPLY_SUGGESTION_ACTION, user)
        end

        def track_users_assigned_to_mr(users:)
          track_unique_action_by_users(MR_ASSIGNED_USERS_ACTION, users)
        end

        def track_users_review_requested(users:)
          track_unique_action_by_users(MR_REVIEW_REQUESTED_USERS_ACTION, users)
        end

        def track_title_edit_action(user:)
          track_unique_action_by_user(MR_EDIT_MR_TITLE_ACTION, user)
        end

        def track_description_edit_action(user:)
          track_unique_action_by_user(MR_EDIT_MR_DESC_ACTION, user)
        end

        def track_approval_rule_added_action(user:)
          track_unique_action_by_user(MR_APPROVAL_RULE_ADDED_USERS_ACTION, user)
        end

        def track_approval_rule_edited_action(user:)
          track_unique_action_by_user(MR_APPROVAL_RULE_EDITED_USERS_ACTION, user)
        end

        def track_approval_rule_deleted_action(user:)
          track_unique_action_by_user(MR_APPROVAL_RULE_DELETED_USERS_ACTION, user)
        end

        def track_task_item_status_changed(user:)
          track_unique_action_by_user(MR_TASK_ITEM_STATUS_CHANGED_ACTION, user)
        end

        def track_mr_create_from_issue(user:)
          track_unique_action_by_user(MR_CREATE_FROM_ISSUE_ACTION, user)
        end

        def track_discussion_locked_action(user:)
          track_unique_action_by_user(MR_DISCUSSION_LOCKED_ACTION, user)
        end

        def track_discussion_unlocked_action(user:)
          track_unique_action_by_user(MR_DISCUSSION_UNLOCKED_ACTION, user)
        end

        def track_time_estimate_changed_action(user:)
          track_unique_action_by_user(MR_TIME_ESTIMATE_CHANGED_ACTION, user)
        end

        def track_time_spent_changed_action(user:)
          track_unique_action_by_user(MR_TIME_SPENT_CHANGED_ACTION, user)
        end

        def track_assignees_changed_action(user:)
          track_unique_action_by_user(MR_ASSIGNEES_CHANGED_ACTION, user)
        end

        def track_reviewers_changed_action(user:)
          track_unique_action_by_user(MR_REVIEWERS_CHANGED_ACTION, user)
        end

        def track_mr_including_ci_config(user:, merge_request:)
          return unless merge_request.includes_ci_config?

          track_unique_action_by_user(MR_INCLUDING_CI_CONFIG_ACTION, user)
        end

        def track_milestone_changed_action(user:)
          track_unique_action_by_user(MR_MILESTONE_CHANGED_ACTION, user)
        end

        def track_labels_changed_action(user:)
          track_unique_action_by_user(MR_LABELS_CHANGED_ACTION, user)
        end

        def track_loading_conflict_ui_action(user:)
          track_unique_action_by_user(MR_LOAD_CONFLICT_UI_ACTION, user)
        end

        def track_resolve_conflict_action(user:)
          track_unique_action_by_user(MR_RESOLVE_CONFLICT_ACTION, user)
        end

        private

        def track_unique_action_by_merge_request(action, merge_request)
          track_unique_action(action, merge_request.id)
        end

        def track_unique_action_by_user(action, user)
          return unless user

          track_unique_action(action, user.id)
        end

        def track_unique_action_by_users(action, users)
          return if users.blank?

          track_unique_action(action, users.map(&:id))
        end

        def track_unique_action(action, value)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(action, value)
        end

        def track_multiline_unique_action(action, note)
          return unless note.is_a?(DiffNote) && note.multiline?

          track_unique_action_by_user(action, note.author)
        end
      end
    end
  end
end
