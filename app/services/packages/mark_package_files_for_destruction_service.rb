# frozen_string_literal: true

module Packages
  # WARNING: ensure that permissions are verified before using this service.
  class MarkPackageFilesForDestructionService
    BATCH_SIZE = 500

    def initialize(package_files)
      @package_files = package_files
    end

    def execute
      @package_files.each_batch(of: BATCH_SIZE) do |batched_package_files|
        batched_package_files.update_all(status: :pending_destruction)
      end

      service_response_success('Package files are now pending destruction')
    end

    private

    def service_response_success(message)
      ServiceResponse.success(message: message)
    end
  end
end
