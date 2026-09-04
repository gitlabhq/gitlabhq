# frozen_string_literal: true

module Import
  module BitbucketImport
    class ClientFactory
      def self.for(project)
        params = project.import_data.credentials.merge(logger: Gitlab::BitbucketImport::Logger)

        # Only OAuth imports refresh tokens (see TokenRefreshStrategy). API-token imports
        # must keep working on instances with no Bitbucket OAuth provider configured.
        provider = Gitlab::Auth::OAuth::Provider.config_for('bitbucket')
        params.merge!(app_id: provider.app_id, app_secret: provider.app_secret) if provider

        Bitbucket::Client.new(
          params,
          http_client: Import::Clients::HTTP,
          refresh_strategy: TokenRefreshStrategy.new(project)
        )
      end
    end
  end
end
