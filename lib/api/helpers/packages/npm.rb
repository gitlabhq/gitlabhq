# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Npm
        include Gitlab::Utils::StrongMemoize
        include ::API::Helpers::PackagesHelpers
        extend ::Gitlab::Utils::Override

        NPM_ENDPOINT_REQUIREMENTS = {
          package_name: API::NO_SLASH_URL_PART_REGEX
        }.freeze

        def project_or_nil
          # mainly used by the metadata endpoint where we need to get a project
          # and return nil if not found (no errors should be raised)
          return unless project_id_or_nil

          find_project(project_id_or_nil)
        end
        strong_memoize_attr :project_or_nil

        def enqueue_sync_metadata_cache_worker(project, package_name)
          ::Packages::Npm::CreateMetadataCacheWorker.perform_async(project.id, package_name)
        end

        private

        override :not_found!
        def not_found!(resource = nil)
          reason = "#{resource} not found"
          message = "404 #{reason}".titleize
          render_structured_api_error!({ message: message, error: reason }, 404)
        end
      end
    end
  end
end
