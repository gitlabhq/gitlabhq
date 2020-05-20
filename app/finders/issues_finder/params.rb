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
      return @user_can_see_all_confidential_issues if defined?(@user_can_see_all_confidential_issues)

      return @user_can_see_all_confidential_issues = false if current_user.blank?
      return @user_can_see_all_confidential_issues = true if current_user.can_read_all_resources?

      @user_can_see_all_confidential_issues =
        if project? && project
          project.team.max_member_access(current_user.id) >= CONFIDENTIAL_ACCESS_LEVEL
        elsif group
          group.max_member_access_for_user(current_user) >= CONFIDENTIAL_ACCESS_LEVEL
        else
          false
        end
    end

    def user_cannot_see_confidential_issues?
      return false if user_can_see_all_confidential_issues?

      current_user.blank?
    end
  end
end

IssuesFinder::Params.prepend_if_ee('EE::IssuesFinder::Params')
