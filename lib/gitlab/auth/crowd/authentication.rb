# frozen_string_literal: true

module Gitlab
  module Auth
    module Crowd
      class Authentication < Gitlab::Auth::OAuth::Authentication
        def login(login, password)
          return unless Gitlab::Auth::OAuth::Provider.enabled?(@provider)
          return unless login.present? && password.present?

          user_info = user_info_from_authentication(login, password)
          return unless user_info&.key?(:user)

          Gitlab::Auth::OAuth::User.find_by_uid_and_provider(user_info[:user], provider)
        end

        private

        def config
          gitlab_crowd_config = Gitlab::Auth::OAuth::Provider.config_for(@provider)
          raise "OmniAuth Crowd is not configured." unless gitlab_crowd_config && gitlab_crowd_config[:args]

          OmniAuth::Strategies::Crowd::Configuration.new(
            gitlab_crowd_config[:args].symbolize_keys)
        end

        def user_info_from_authentication(login, password)
          validator = OmniAuth::Strategies::Crowd::CrowdValidator.new(
            config, login, password, RequestContext.instance.client_ip, nil)
          validator&.user_info&.symbolize_keys
        end
      end
    end
  end
end
