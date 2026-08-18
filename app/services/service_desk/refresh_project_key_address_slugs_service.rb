# frozen_string_literal: true

module ServiceDesk
  # Recomputes project_key_address_slug for projects under a route path whose
  # full path changed indirectly (for example, an ancestor group rename or
  # transfer), which bypasses the Project and ServiceDeskSetting callbacks. Runs
  # in the caller's transaction so a collision rolls back the whole operation.
  class RefreshProjectKeyAddressSlugsService
    AddressSlugConflictError = Class.new(StandardError)

    BATCH_SIZE = 100

    def initialize(route_path)
      @route_path = route_path
    end

    def execute
      return if route_path.blank?

      settings_to_refresh.each_batch(of: BATCH_SIZE) do |batch|
        batch.preload_project.find_each do |setting|
          setting.refresh_project_key_address_slug!
        rescue ActiveRecord::RecordInvalid => e
          raise AddressSlugConflictError, setting.project.full_path if e.record.errors.key?(:project_key)

          raise
        end
      end
    end

    private

    attr_reader :route_path

    def settings_to_refresh
      ServiceDeskSetting.for_projects_inside_route_path(route_path).with_any_project_key
    end
  end
end
