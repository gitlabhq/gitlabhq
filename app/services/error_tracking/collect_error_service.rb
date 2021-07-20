# frozen_string_literal: true

module ErrorTracking
  class CollectErrorService < ::BaseService
    def execute
      # Error is a way to group events based on common data like name or cause
      # of exception. We need to keep a sane balance here between taking too little
      # and too much data into group logic.
      error = project.error_tracking_errors.report_error(
        name: exception['type'], # Example: ActionView::MissingTemplate
        description: exception['value'], # Example: Missing template posts/show in...
        actor: event['transaction'], # Example: PostsController#show
        platform: event['platform'], # Example: ruby
        timestamp: event['timestamp']
      )

      # The payload field contains all the data on error including stacktrace in jsonb.
      # Together with occured_at these are 2 main attributes that we need to save here.
      error.events.create!(
        environment: event['environment'],
        description: exception['type'],
        level: event['level'],
        occurred_at: event['timestamp'],
        payload: event
      )
    end

    private

    def event
      params[:event]
    end

    def exception
      event['exception']['values'].first
    end
  end
end
