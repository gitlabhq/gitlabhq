# frozen_string_literal: true

module Import
  module BitbucketImport
    class ClientFactory
      def self.for(project)
        Bitbucket::Client.new(
          project.import_data.credentials,
          refresh_strategy: TokenRefreshStrategy.new(project)
        )
      end
    end
  end
end
