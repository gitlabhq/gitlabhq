# frozen_string_literal: true

module Import
  module BulkImports
    class UpdateSourceUsersService
      # Default API max page size
      BATCH_SIZE = GitlabSchema.default_max_page_size

      def initialize(bulk_import:, namespace:)
        @bulk_import = bulk_import
        @namespace = namespace
      end

      def execute
        fetch_users_data.each do |user_data|
          update_source_user(user_data)
        end

        ServiceResponse.success
      end

      private

      attr_reader :bulk_import, :namespace, :force

      def graphql_client
        @graphql_client ||= ::BulkImports::Clients::Graphql.new(
          url: bulk_import.configuration.url,
          token: bulk_import.configuration.access_token
        )
      end

      def source_users_with_missing_information
        Import::SourceUser.source_users_with_missing_information(
          namespace: namespace,
          source_hostname: Gitlab::UrlHelpers.normalized_base_url(bulk_import.configuration.url),
          import_type: Import::SOURCE_DIRECT_TRANSFER
        )
      end

      def find_source_user(source_user_identifier)
        Import::SourceUser.find_source_user(
          source_user_identifier: source_user_identifier,
          namespace: namespace,
          source_hostname: Gitlab::UrlHelpers.normalized_base_url(bulk_import.configuration.url),
          import_type: Import::SOURCE_DIRECT_TRANSFER
        )
      end

      def user_global_ids(batch)
        batch.map do |source_user|
          Gitlab::GlobalId.as_global_id(source_user.source_user_identifier, model_name: 'User').to_s
        end
      end

      def fetch_users_data
        Enumerator.new do |yielder|
          source_users_with_missing_information.each_batch(of: BATCH_SIZE, order: :desc) do |batch|
            ids = user_global_ids(batch)
            has_next_page = true
            next_page = nil

            # Make subsequent API calls if the API is configured with a max
            # page size smaller than the default value
            while has_next_page
              response = graphql_client.execute(parsed_query, ids: ids, after: next_page).original_hash

              data = response.dig('data', 'users')
              next_page = data.dig('pageInfo', 'next_page')
              has_next_page = data.dig('pageInfo', 'has_next_page')
              users = data['nodes']

              unless users.present?
                logger.error(message: 'No users present in response', response: response, user_ids: ids)
                next
              end

              users.each do |user|
                yielder << user
              end
            end
          end
        end
      end

      def update_source_user(user_data)
        source_user_identifier = GlobalID.parse(user_data['id'])&.model_id

        unless source_user_identifier
          logger.error(message: 'Missing source user identifier', user_data: user_data)
          return
        end

        source_user = find_source_user(source_user_identifier)
        return unless source_user

        params = { source_name: user_data['name'], source_username: user_data['username'] }.compact

        if params.blank?
          logger.error(message: 'Missing source user information', user_data: user_data, source_user_id: source_user.id,
            bulk_import_id: bulk_import.id,
            importer: Import::SOURCE_DIRECT_TRANSFER)
          return
        end

        result = SourceUsers::UpdateService.new(source_user, params).execute

        if result.success?
          logger.info(message: 'Source user updated', source_user_id: source_user.id, bulk_import_id: bulk_import.id,
            importer: Import::SOURCE_DIRECT_TRANSFER)
          return
        end

        logger.error(message: 'Failed to update source user', source_user_id: source_user.id, error: result.message,
          bulk_import_id: bulk_import.id, importer: Import::SOURCE_DIRECT_TRANSFER)
      end

      def parsed_query
        @parsed_query ||= graphql_client.parse(Common::Graphql::GetUsersQuery.new.to_s)
      end

      def logger
        @logger ||= ::BulkImports::Logger.build
      end
    end
  end
end
