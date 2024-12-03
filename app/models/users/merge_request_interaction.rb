# frozen_string_literal: true

module Users
  class MergeRequestInteraction
    def initialize(user:, merge_request:, current_user: nil)
      @user = user
      @merge_request = merge_request
      @current_user = current_user
    end

    def declarative_policy_subject
      merge_request
    end

    def can_merge?
      merge_request.can_be_merged_by?(user)
    end

    def can_update?
      user.can?(:update_merge_request, merge_request)
    end

    def review_state
      reviewer&.state
    end

    def reviewed?
      reviewer&.reviewed? == true
    end

    def approved?
      merge_request.approvals.any? { |app| app.user_id == user.id }
    end

    private

    def reviewer
      @reviewer ||= merge_request.merge_request_reviewers.find { |r| r.user_id == user.id }
    end

    attr_reader :user, :merge_request, :current_user
  end
end

::Users::MergeRequestInteraction.prepend_mod_with('Users::MergeRequestInteraction')
