# frozen_string_literal: true
module Gitlab
  module Auth
    module Otp
      module Fortinet
        private

        def forti_authenticator_enabled?(user)
          ::Gitlab.config.forti_authenticator.enabled &&
            Feature.enabled?(:forti_authenticator, user)
        end

        def forti_token_cloud_enabled?(user)
          ::Gitlab.config.forti_token_cloud.enabled &&
            Feature.enabled?(:forti_token_cloud, user)
        end
      end
    end
  end
end
