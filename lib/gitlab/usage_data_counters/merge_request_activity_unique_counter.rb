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

        def track_apply_suggestion_action(user:)
          track_unique_action_by_user(MR_APPLY_SUGGESTION_ACTION, user)
        end

        private

        def track_unique_action_by_merge_request(action, merge_request)
          track_unique_action(action, merge_request.id)
        end

        def track_unique_action_by_user(action, user)
          return unless user

          track_unique_action(action, user.id)
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
