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
      collection = sort(collection)

      # Limit collection until pagination implemented.
      limit(collection)
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

    def sort(collection)
      params[:sort] ? collection.sort_by_attribute(params[:sort]) : collection.order_id_desc
    end

    def limit(collection)
      # Restrict the maximum limit at 100 records.
      collection.limit([(params[:limit] || 20).to_i, 100].min)
    end
  end
end
