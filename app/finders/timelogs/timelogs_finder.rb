# frozen_string_literal: true

module Timelogs
  class TimelogsFinder
    attr_reader :parent, :params

    def initialize(parent, params = {})
      @parent = parent
      @params = params
    end

    def execute
      timelogs = parent&.timelogs || Timelog.all
      timelogs = by_time(timelogs)
      timelogs = by_user(timelogs)
      timelogs = by_group(timelogs)
      timelogs = by_project(timelogs)
      apply_sorting(timelogs)
    end

    private

    def by_time(timelogs)
      return timelogs unless params[:start_time] || params[:end_time]

      validate_time_difference!

      timelogs = timelogs.at_or_after(params[:start_time]) if params[:start_time]
      timelogs = timelogs.at_or_before(params[:end_time]) if params[:end_time]

      timelogs
    end

    def by_user(timelogs)
      return timelogs unless params[:username]

      user = User.find_by_username(params[:username])
      timelogs.for_user(user)
    end

    def by_group(timelogs)
      return timelogs unless params[:group_id]

      group = Group.find_by_id(params[:group_id])
      raise(ActiveRecord::RecordNotFound, "Group with id '#{params[:group_id]}' could not be found") unless group

      timelogs.in_group(group)
    end

    def by_project(timelogs)
      return timelogs unless params[:project_id]

      timelogs.in_project(params[:project_id])
    end

    def apply_sorting(timelogs)
      return timelogs unless params[:sort]

      timelogs.sort_by_field(params[:sort])
    end

    def validate_time_difference!
      return unless end_time_before_start_time?

      raise ArgumentError, 'Start argument must be before End argument'
    end

    def end_time_before_start_time?
      times_provided? && params[:end_time] < params[:start_time]
    end

    def times_provided?
      params[:start_time] && params[:end_time]
    end
  end
end
