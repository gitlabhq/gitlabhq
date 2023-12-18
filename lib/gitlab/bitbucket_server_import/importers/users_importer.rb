# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class UsersImporter
        include Loggable
        include UserCaching

        BATCH_SIZE = 100

        def initialize(project)
          @project = project
          @project_id = project.id
        end

        attr_reader :project, :project_id

        def execute
          log_info(import_stage: 'import_users', message: 'starting')

          page = 1

          loop do
            log_info(
              import_stage: 'import_users',
              message: "importing page #{page} using batch size #{BATCH_SIZE}"
            )

            users = client.users(project_key, page_offset: page, limit: BATCH_SIZE).to_a

            break if users.empty?

            cache_users(users)

            page += 1
          end

          log_info(import_stage: 'import_users', message: 'finished')
        end

        private

        def cache_users(users)
          users_hash = users.each_with_object({}) do |user, hash|
            cache_key = source_user_cache_key(project_id, user.username)
            hash[cache_key] = user.email
          end

          ::Gitlab::Cache::Import::Caching.write_multiple(users_hash)
        end

        def client
          @client ||= BitbucketServer::Client.new(project.import_data.credentials)
        end

        def project_key
          project.import_data.data['project_key']
        end
      end
    end
  end
end
