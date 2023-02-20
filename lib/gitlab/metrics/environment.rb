# frozen_string_literal: true

module Gitlab
  module Metrics
    module Environment
      class << self
        def web?
          service?('web')
        end

        def api?
          service?('api')
        end

        def git?
          service?('git')
        end

        def service?(name)
          env_var = ENV.fetch('GITLAB_METRICS_INITIALIZE', '')
          return true unless env_var.present?

          env_var == name
        end
      end
    end
  end
end
