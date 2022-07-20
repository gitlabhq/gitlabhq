# frozen_string_literal: true

module Packages
  # WARNING: ensure that permissions are verified before using this service.
  class MarkPackageFilesForDestructionService
    BATCH_SIZE = 500

    def initialize(package_files)
      @package_files = package_files
    end

    def execute(batch_deadline: nil, batch_size: BATCH_SIZE)
      timeout = false
      updates_count = 0
      min_batch_size = [batch_size, BATCH_SIZE].min

      @package_files.each_batch(of: min_batch_size) do |batched_package_files|
        if batch_deadline && Time.zone.now > batch_deadline
          timeout = true
          break
        end

        updates_count += batched_package_files.update_all(status: :pending_destruction)
      end

      payload = { marked_package_files_count: updates_count }

      return response_error(payload) if timeout

      response_success(payload)
    end

    private

    def response_success(payload)
      ServiceResponse.success(
        message: 'Package files are now pending destruction',
        payload: payload
      )
    end

    def response_error(payload)
      ServiceResponse.error(
        message: 'Timeout while marking package files as pending destruction',
        payload: payload
      )
    end
  end
end
