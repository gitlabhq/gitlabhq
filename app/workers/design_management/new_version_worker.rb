# frozen_string_literal: true

module DesignManagement
  class NewVersionWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :design_management
    # Declare this worker as memory bound due to
    # `GenerateImageVersionsService` resizing designs
    worker_resource_boundary :memory

    def perform(version_id, skip_system_notes = false)
      version = DesignManagement::Version.find(version_id)

      add_system_note(version) unless skip_system_notes
      generate_image_versions(version)
    rescue ActiveRecord::RecordNotFound => e
      Sidekiq.logger.warn(e)
    end

    private

    def add_system_note(version)
      SystemNoteService.design_version_added(version)
    end

    def generate_image_versions(version)
      DesignManagement::GenerateImageVersionsService.new(version).execute
    end
  end
end
