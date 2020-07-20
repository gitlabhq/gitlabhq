# frozen_string_literal: true

module ProductAnalytics
  class CollectorApp
    def call(env)
      request = Rack::Request.new(env)
      params = request.params

      return not_found unless EventParams.has_required_params?(params)

      # Product analytics feature is behind a flag and is disabled by default.
      # We expect limited amount of projects with this feature enabled in first release.
      # Since collector has no authentication we temporary prevent recording of events
      # for project without the feature enabled. During increase of feature adoption, this
      # check will be removed for better performance.
      project = Project.find(params['aid'].to_i)
      return not_found unless Feature.enabled?(:product_analytics, project, default_enabled: false)

      # Snowplow tracker has own format of events.
      # We need to convert them to match the schema of our database.
      event_params = EventParams.parse_event_params(params)

      if ProductAnalyticsEvent.create(event_params)
        ok
      else
        not_found
      end
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotFound
      not_found
    end

    def ok
      [200, {}, []]
    end

    def not_found
      [404, {}, []]
    end
  end
end
