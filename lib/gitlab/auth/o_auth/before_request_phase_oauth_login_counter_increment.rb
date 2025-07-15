# frozen_string_literal: true

module Gitlab
  module Auth
    module OAuth
      module BeforeRequestPhaseOauthLoginCounterIncrement
        def self.counter
          Gitlab::Metrics.counter(:gitlab_omniauth_login_total, 'Counter of initiated OmniAuth login attempts')
        end

        def self.call(env)
          provider = current_provider_name_from(env)
          return unless provider

          counter.increment(omniauth_provider: provider, status: 'initiated')
        end

        private_class_method def self.current_provider_name_from(env)
          env['omniauth.strategy']&.name
        end
      end
    end
  end
end
