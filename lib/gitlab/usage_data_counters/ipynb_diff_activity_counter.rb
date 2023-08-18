# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module IpynbDiffActivityCounter
      NOTE_CREATED_IN_IPYNB_DIFF_ACTION = 'i_code_review_create_note_in_ipynb_diff'
      USER_CREATED_NOTE_IN_IPYNB_DIFF_ACTION = 'i_code_review_user_create_note_in_ipynb_diff'
      NOTE_CREATED_IN_IPYNB_DIFF_MR_ACTION = 'i_code_review_create_note_in_ipynb_diff_mr'
      USER_CREATED_NOTE_IN_IPYNB_DIFF_MR_ACTION = 'i_code_review_user_create_note_in_ipynb_diff_mr'
      NOTE_CREATED_IN_IPYNB_DIFF_COMMIT_ACTION = 'i_code_review_create_note_in_ipynb_diff_commit'
      USER_CREATED_NOTE_IN_IPYNB_DIFF_COMMIT_ACTION = 'i_code_review_user_create_note_in_ipynb_diff_commit'

      class << self
        def note_created(note)
          return unless note.for_merge_request? || note.for_commit?

          if note.for_merge_request?
            track(NOTE_CREATED_IN_IPYNB_DIFF_MR_ACTION, USER_CREATED_NOTE_IN_IPYNB_DIFF_MR_ACTION, note)
          else
            track(NOTE_CREATED_IN_IPYNB_DIFF_COMMIT_ACTION, USER_CREATED_NOTE_IN_IPYNB_DIFF_COMMIT_ACTION, note)
          end

          track(NOTE_CREATED_IN_IPYNB_DIFF_ACTION, USER_CREATED_NOTE_IN_IPYNB_DIFF_ACTION, note)
        end

        private

        def track(action, per_user_action, note)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(action, note.id)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(per_user_action, note.author_id)
        end
      end
    end
  end
end
