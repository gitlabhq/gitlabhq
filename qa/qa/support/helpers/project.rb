# frozen_string_literal: true

module QA
  module Support
    module Helpers
      module Project
        def wait_until_project_is_ready(project)
          # Repository can take a short time to become ready after project is created
          Support::Retrier.retry_on_exception(sleep_interval: 1, max_attempts: 60) do
            create(:commit, project: project, commit_message: 'Add new file', actions: [
              { action: 'create', file_path: SecureRandom.hex(4), content: '# This is a new file' }
            ])
          end
        end

        def wait_until_token_associated_to_project(project, api_client)
          Support::Retrier.retry_on_exception(sleep_interval: 1, max_attempts: 60) do
            create(
              :commit,
              project: project,
              actions: [{ action: 'create', file_path: SecureRandom.hex(4) }],
              api_client: api_client
            )
          end
        end
      end
    end
  end
end
