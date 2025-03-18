# frozen_string_literal: true

module Gitlab
  module Auth
    module OAuth
      module BeforeRequestPhaseOauthLoginCounterIncrement
        OMNIAUTH_LOGIN_TOTAL_COUNTER =
          Gitlab::Metrics.counter(:gitlab_omniauth_login_total, 'Counter of initiated OmniAuth login attempts')

        def self.call(env)
          provider = current_provider_name_from(env)
          return unless provider

          OMNIAUTH_LOGIN_TOTAL_COUNTER.increment(omniauth_provider: provider, status: 'initiated')
        end

        private_class_method def self.current_provider_name_from(env)
          env['omniauth.strategy']&.name
        end
      end
    end
  end
end
