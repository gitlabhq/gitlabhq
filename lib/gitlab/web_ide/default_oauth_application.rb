# frozen_string_literal: true

module Gitlab
  module WebIde
    module DefaultOauthApplication
      class << self
        def feature_enabled?(current_user)
          Feature.enabled?(:vscode_web_ide, current_user) && Feature.enabled?(:web_ide_oauth, current_user)
        end

        def oauth_application
          application_settings.web_ide_oauth_application
        end

        def oauth_callback_url
          Gitlab::Routing.url_helpers.ide_oauth_redirect_url
        end

        def ensure_oauth_application!
          return if oauth_application

          should_expire_cache = false

          application_settings.transaction do
            # note: This should run very rarely and should be safe for us to do a lock
            #       https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132496#note_1587293087
            application_settings.lock!

            # note: `lock!`` breaks applicaiton_settings cache and will trigger another query.
            # We need to double check here so that requests previously waiting on the lock can
            # now just skip.
            next if oauth_application

            application = Doorkeeper::Application.new(
              name: 'GitLab Web IDE',
              redirect_uri: oauth_callback_url,
              scopes: ['api'],
              trusted: true,
              confidential: false)
            application.save!
            application_settings.update!(web_ide_oauth_application: application)
            should_expire_cache = true
          end

          # note: This needs to happen outside the transaction, but only if we actually changed something
          ::Gitlab::CurrentSettings.expire_current_application_settings if should_expire_cache
        end

        private

        def application_settings
          ::Gitlab::CurrentSettings.current_application_settings
        end
      end
    end
  end
end
