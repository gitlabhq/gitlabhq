# frozen_string_literal: true

module QA
  module Support
    module Helpers
      module Project
        def wait_until_project_is_ready(project)
          # Repository can take a short time to become ready after project is created
          Support::Retrier.retry_on_exception(sleep_interval: 5) do
            create(:commit, project: project, commit_message: 'Add new file', actions: [
              { action: 'create', file_path: 'new_file', content: '# This is a new file' }
            ])
          end
        end
      end
    end
  end
end
