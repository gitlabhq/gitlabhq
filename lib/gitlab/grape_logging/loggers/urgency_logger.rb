# frozen_string_literal: true

module Gitlab
  module GrapeLogging
    module Loggers
      class UrgencyLogger < ::GrapeLogging::Loggers::Base
        def parameters(request, _)
          endpoint = request.env['api.endpoint']
          return {} unless endpoint

          urgency = endpoint.options[:for].try(:urgency_for_app, endpoint)
          return {} unless urgency

          { request_urgency: urgency.name, target_duration_s: urgency.duration }
        end
      end
    end
  end
end
