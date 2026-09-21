# frozen_string_literal: true

module Import
  module Github
    # Creates an importer-compatible API client from installation identity.
    class ClientFactory
      def initialize(installation_id, token_service: nil)
        @installation_id = installation_id
        @token_service = token_service || InstallationTokenService.new(installation_id)
      end

      # A fresh installation token is scoped to this client and is not exposed
      # to the caller or persisted by the factory.
      def create(parallel: true, per_page: Gitlab::GithubImport::Client::DEFAULT_PER_PAGE)
        build_client(
          token_service.execute,
          token_refresher: method(:refresh_token),
          parallel: parallel,
          per_page: per_page
        )
      end

      # Creates an importer client whose provider credential is restricted to
      # one durable repository identity. A successful mint is the provider's
      # fresh proof that the App installation still selects that repository.
      # It performs a token request now and retains the same in-memory scope for
      # an unauthorized-response refresh; neither value is persisted.
      #
      # @param repository_id [Integer] positive stable provider repository identity
      # @param parallel [Boolean] whether importer API requests may run concurrently
      # @param per_page [Integer] importer API pagination size
      # @return [Gitlab::GithubImport::Client] refreshable repository-scoped client
      # @raise [InstallationTokenService::ConfigurationError] when the repository identity is invalid
      # @raise [InstallationTokenService::RepositoryNotSelectedError] when the App does not select the repository
      def create_for_repository(
        repository_id:,
        parallel: true,
        per_page: Gitlab::GithubImport::Client::DEFAULT_PER_PAGE
      )
        build_client(
          token_service.execute(repository_id: repository_id),
          token_refresher: -> { refresh_token(repository_id: repository_id) },
          parallel: parallel,
          per_page: per_page
        )
      end

      private

      attr_reader :installation_id, :token_service

      # Builds one importer client around a short-lived redacting token.
      # The token remains in memory and refresh failures propagate to the caller.
      def build_client(token, token_refresher:, parallel:, per_page:)
        Gitlab::GithubImport::Client.new(
          token.value,
          per_page: per_page,
          parallel: parallel,
          token_refresher: token_refresher
        )
      end

      # Mints a replacement only after the client observes an unauthorized API
      # response, bypassing the cached token for this scope. The token remains
      # an in-memory String consumed immediately by the client and is never
      # attached to a model or a job argument.
      #
      # @param repository_id [Integer, nil] frozen scope retained from client creation
      # @return [String] replacement credential for immediate in-memory client use
      # @raise [InstallationTokenService::TokenRequestError] when refresh cannot proceed
      def refresh_token(repository_id: nil)
        token_service.execute(repository_id: repository_id, force_refresh: true).value
      end
    end
  end
end
