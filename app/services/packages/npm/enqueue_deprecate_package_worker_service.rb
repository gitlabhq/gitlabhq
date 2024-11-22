# frozen_string_literal: true

module Packages
  module Npm
    class EnqueueDeprecatePackageWorkerService < BaseService
      def execute
        deprecated_versions

        validation_response = validate!
        return validation_response if validation_response&.error?

        enqueue_worker

        ServiceResponse.success
      end

      private

      def deprecated_versions
        versions.select! { |_, package| package['deprecated'] }
      end

      def validate!
        return if versions.any?

        ServiceResponse.error(message: 'no versions to deprecate', reason: :no_versions_to_deprecate)
      end

      def enqueue_worker
        ::Packages::Npm::DeprecatePackageWorker.perform_async(project.id, params)
      end

      def versions
        params['versions']
      end
    end
  end
end
