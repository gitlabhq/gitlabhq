# frozen_string_literal: true

class IssuesFinder
  class Params < IssuableFinder::Params
    def public_only?
      params.fetch(:public_only, false)
    end

    def filter_by_no_due_date?
      due_date? && params[:due_date] == Issue::NoDueDate.name
    end

    def filter_by_overdue?
      due_date? && params[:due_date] == Issue::Overdue.name
    end

    def filter_by_due_this_week?
      due_date? && params[:due_date] == Issue::DueThisWeek.name
    end

    def filter_by_due_this_month?
      due_date? && params[:due_date] == Issue::DueThisMonth.name
    end

    def filter_by_due_next_month_and_previous_two_weeks?
      due_date? && params[:due_date] == Issue::DueNextMonthAndPreviousTwoWeeks.name
    end

    def user_can_see_all_confidential_issues?
      strong_memoize(:user_can_see_all_confidential_issues) do
        parent = project? ? project : group
        if parent
          Ability.allowed?(current_user, :read_confidential_issues, parent)
        else
          Ability.allowed?(current_user, :read_all_resources)
        end
      end
    end

    def user_cannot_see_confidential_issues?
      return false if user_can_see_all_confidential_issues?

      current_user.blank?
    end
  end
end

IssuesFinder::Params.prepend_mod_with('IssuesFinder::Params')
