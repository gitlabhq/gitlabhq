# frozen_string_literal: true

module Import
  module BitbucketImport
    class ClientFactory
      def self.for(project)
        provider = Gitlab::Auth::OAuth::Provider.config_for('bitbucket')

        params = project.import_data.credentials.merge(
          logger: Gitlab::BitbucketImport::Logger,
          # Required to refresh the OAuth token during import (see TokenRefreshStrategy).
          app_id: provider.app_id,
          app_secret: provider.app_secret
        )

        Bitbucket::Client.new(
          params,
          http_client: Import::Clients::HTTP,
          refresh_strategy: TokenRefreshStrategy.new(project)
        )
      end
    end
  end
end
