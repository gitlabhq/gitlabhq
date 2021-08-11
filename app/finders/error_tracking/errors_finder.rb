# frozen_string_literal: true

module ErrorTracking
  class ErrorsFinder
    def initialize(current_user, project, params)
      @current_user = current_user
      @project = project
      @params = params
    end

    def execute
      return ErrorTracking::Error.none unless authorized?

      collection = project.error_tracking_errors
      collection = by_status(collection)

      # Limit collection until pagination implemented
      collection.limit(20)
    end

    private

    attr_reader :current_user, :project, :params

    def by_status(collection)
      if params[:status].present? && ErrorTracking::Error.statuses.key?(params[:status])
        collection.for_status(params[:status])
      else
        collection
      end
    end

    def authorized?
      Ability.allowed?(current_user, :read_sentry_issue, project)
    end
  end
end
