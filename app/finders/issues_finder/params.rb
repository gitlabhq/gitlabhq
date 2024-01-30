# frozen_string_literal: true

class IssuesFinder
  class Params < IssuableFinder::Params
    def filter_by_any_due_date?
      due_date? && params[:due_date] == Issue::AnyDueDate.name
    end

    def filter_by_no_due_date?
      due_date? && params[:due_date] == Issue::NoDueDate.name
    end

    def filter_by_overdue?
      due_date? && params[:due_date] == Issue::Overdue.name
    end

    def filter_by_due_today?
      due_date? && params[:due_date] == Issue::DueToday.name
    end

    def filter_by_due_tomorrow?
      due_date? && params[:due_date] == Issue::DueTomorrow.name
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
  end
end

IssuesFinder::Params.prepend_mod_with('IssuesFinder::Params')
