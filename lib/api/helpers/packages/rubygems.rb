# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Rubygems
        def enqueue_create_spec_files_worker(project)
          ::Packages::Rubygems::CreateSpecFilesWorker.perform_async(project.id)
        end
      end
    end
  end
end
