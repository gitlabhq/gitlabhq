# frozen_string_literal: true

module BulkImports # rubocop:disable Gitlab/BoundedContexts -- legacy use
  class SourceInternalUserFinder
    GHOST_USER_CACHE_KEY = 'bulk_imports/ghost_user_id/%{bulk_import_id}'
    MAX_RETRIES = 3

    class << self
      def cache_ghost_user_id(bulk_import_id, ghost_user_id)
        Gitlab::Cache::Import::Caching.write(cache_key(bulk_import_id), ghost_user_id)
      end

      def cached_ghost_user_id(bulk_import_id)
        Gitlab::Cache::Import::Caching.read(cache_key(bulk_import_id))
      end

      private

      def cache_key(bulk_import_id)
        format(GHOST_USER_CACHE_KEY, bulk_import_id: bulk_import_id)
      end
    end

    # @param [BulkImports::Configuration] configuration
    def initialize(configuration)
      @configuration = configuration
    end

    # @return [Hash, nil]
    def fetch_ghost_user
      attempt = 0

      begin
        attempt += 1
        query = <<~GRAPHQL
          {
            users(usernames: ["ghost", "ghost1", "ghost2", "ghost3", "ghost4", "ghost5", "ghost6"], humans: false) {
              nodes {
                id
                username
                type
              }
            }
          }
        GRAPHQL

        response = client.execute(query: query)
        response = response.dig('data', 'users', 'nodes') || []
        response.find { |user| user["type"] == 'GHOST' }
      rescue StandardError => e
        if attempt < MAX_RETRIES
          delay = 2**attempt # Exponential backoff (2, 4, 8...)
          sleep(delay)
          retry
        end

        Gitlab::ErrorTracking.track_exception(e,
          { message: "Failed to fetch ghost user after #{MAX_RETRIES} attempts",
            bulk_import_id: configuration.bulk_import_id }
        )
        nil
      end
    end

    # @return [String, nil]
    def fetch_and_cache_ghost_id_from_source_instance
      return if cached_ghost_user_id.present?

      ghost_user = fetch_ghost_user
      return unless ghost_user # since fetch_ghost_user returns nil if it's not in the API response

      model_id = GlobalID.parse(ghost_user['id']).model_id

      self.class.cache_ghost_user_id(configuration.bulk_import_id, model_id)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e,
        { message: "Failed to fetch and cache source ghost user ID", bulk_import_id: configuration.bulk_import_id }
      )
      nil
    end

    # Returns the cached ID of the ghost user from the source instance, if it exists.
    #
    # @return [String, nil]
    def cached_ghost_user_id
      self.class.cached_ghost_user_id(configuration.bulk_import_id)
    end

    private

    attr_reader :configuration

    def client
      @client ||= BulkImports::Clients::Graphql.new(
        url: configuration.url,
        token: configuration.access_token
      )
    end
  end
end
