# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class UsersImporter
        include Loggable
        include Gitlab::Import::UserFromMention

        BATCH_SIZE = 100

        def initialize(project)
          @project = project
          @project_id = project.id
        end

        attr_reader :project, :project_id

        def execute
          log_info(import_stage: 'import_users', message: 'starting')

          current = page_counter.current

          loop do
            log_info(
              import_stage: 'import_users',
              message: "importing page #{current} using batch size #{BATCH_SIZE}"
            )

            users = client.users(workspace_key, page_number: current, limit: BATCH_SIZE).to_a

            break if users.empty?

            cache_users(users)

            current += 1
            page_counter.set(current)
          end

          page_counter.expire!

          log_info(import_stage: 'import_users', message: 'finished')
        end

        private

        def cache_users(users)
          # No-op for now
        end

        def client
          @client ||= Bitbucket::Client.new(project.import_data.credentials)
        end

        def workspace_key
          project.import_source.split('/').first
        end

        def page_counter
          @page_counter ||= Gitlab::Import::PageCounter.new(project, :users, 'bitbucket-importer')
        end
      end
    end
  end
end
