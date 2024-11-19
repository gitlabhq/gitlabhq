# frozen_string_literal: true

module Issuables
  class AssigneeFilter < BaseFilter
    def filter(issuables)
      filtered = by_assignee(issuables)
      filtered = by_assignee_union(filtered)
      by_negated_assignee(filtered)
    end

    def includes_user?(user)
      has_assignee_param?(params) && assignee_ids(params).include?(user.id)
    end

    private

    def by_assignee(issuables)
      if filter_by_no_assignee?
        issuables.unassigned
      elsif filter_by_any_assignee?
        issuables.assigned
      elsif has_assignee_param?(params)
        filter_by_assignees(issuables)
      else
        issuables
      end
    end

    def by_assignee_union(issuables)
      return issuables unless has_assignee_param?(or_params)

      issuables.assigned_to(assignee_ids(or_params))
    end

    def by_negated_assignee(issuables)
      return issuables unless has_assignee_param?(not_params)

      issuables.not_assigned_to(assignee_ids(not_params))
    end

    def filter_by_no_assignee?
      params[:assignee_id].to_s.downcase == FILTER_NONE
    end

    def filter_by_any_assignee?
      params[:assignee_id].to_s.downcase == FILTER_ANY
    end

    def filter_by_assignees(issuables)
      assignee_ids = assignee_ids(params)

      return issuables.none if assignee_ids.blank?

      assignee_ids.each do |assignee_id|
        issuables = issuables.assigned_to(assignee_id)
      end

      issuables
    end

    def has_assignee_param?(specific_params)
      return if specific_params.nil?

      specific_params[:assignee_ids].present? ||
        specific_params[:assignee_id].present? ||
        specific_params[:assignee_username].present?
    end

    def assignee_ids(specific_params)
      if specific_params[:assignee_ids].present?
        Array(specific_params[:assignee_ids])
      elsif specific_params[:assignee_id].present?
        Array(specific_params[:assignee_id])
      elsif specific_params[:assignee_username].present?
        User.by_username(specific_params[:assignee_username]).pluck_primary_key
      end
    end
  end
end
