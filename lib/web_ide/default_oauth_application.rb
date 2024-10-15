# frozen_string_literal: true

module WebIde
  module DefaultOauthApplication
    class << self
      def feature_enabled?(current_user)
        Feature.enabled?(:vscode_web_ide, current_user)
      end

      def oauth_application
        application_settings.web_ide_oauth_application
      end

      def oauth_callback_url
        Gitlab::Routing.url_helpers.ide_oauth_redirect_url
      end

      def oauth_application_id
        oauth_application ? oauth_application.id : nil
      end

      def oauth_application_callback_urls
        return [] unless oauth_application

        URI.extract(oauth_application.redirect_uri, %w[http https]).uniq
      end

      def reset_oauth_application_settings
        return unless oauth_application

        oauth_application.update!(default_settings)
      end

      def ensure_oauth_application!
        return if oauth_application

        should_expire_cache = false

        application_settings.transaction do
          # note: This should run very rarely and should be safe for us to do a lock
          #       https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132496#note_1587293087
          application_settings.lock!

          # note: `lock!`` breaks application_settings cache and will trigger another query.
          # We need to double check here so that requests previously waiting on the lock can
          # now just skip.
          next if oauth_application

          application = Doorkeeper::Application.new(default_settings)
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

      def default_settings
        {
          "name" => 'GitLab Web IDE',
          "redirect_uri" => oauth_callback_url,
          "scopes" => ['api'],
          "trusted" => true,
          "confidential" => false
        }.freeze
      end
    end
  end
end
