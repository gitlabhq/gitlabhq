# frozen_string_literal: true

class MergeRequestsFinder
  class Params < IssuableFinder::Params
    def filter_by_no_reviewer?
      params[:reviewer_id].to_s.downcase == FILTER_NONE
    end

    def filter_by_any_reviewer?
      params[:reviewer_id].to_s.downcase == FILTER_ANY
    end

    def reviewer
      strong_memoize(:reviewer) do
        if reviewer_id?
          User.find_by_id(params[:reviewer_id])
        elsif reviewer_username?
          User.find_by_username(params[:reviewer_username])
        end
      end
    end

    def assigned_user
      strong_memoize(:assigned_user) do
        next unless params[:assigned_user_id].present?

        User.find_by_id(params[:assigned_user_id])
      end
    end

    def merge_user
      strong_memoize(:merge_user) do
        if merge_user_id?
          User.find_by_id(params[:merge_user_id])
        elsif merge_user_username?
          User.find_by_username(params[:merge_user_username])
        end
      end
    end

    def assigned_review_states
      return unless params[:assigned_review_states].present?

      params[:assigned_review_states].map { |state| MergeRequestReviewer.states[state] }
    end

    def reviewer_review_states
      return unless params[:reviewer_review_states].present?

      params[:reviewer_review_states].map { |state| MergeRequestReviewer.states[state] }
    end

    def review_state
      if params[:review_state].present?
        MergeRequestReviewer.states[params[:review_state]]
      elsif params[:review_states].present?
        params[:review_states].map { |state| MergeRequestReviewer.states[state] }
      end
    end

    def not_review_states
      return unless params[:not][:review_states].present?

      params[:not][:review_states].map { |state| MergeRequestReviewer.states[state] }
    end
  end
end
