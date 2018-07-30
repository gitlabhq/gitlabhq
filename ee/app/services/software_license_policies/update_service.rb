# frozen_string_literal: true

# Managed license update service. For use in the managed license controller.
module SoftwareLicensePolicies
  class UpdateService < ::BaseService
    def initialize(project, user, params)
      super(project, user, params.with_indifferent_access)
    end

    # returns the updated managed license
    def execute(software_license_policy)
      return error("", 403) unless can?(@current_user, :admin_software_license_policy, @project)

      @params = @params.slice(*SoftwareLicensePolicy::FORM_EDITABLE)

      begin
        software_license_policy.update(params)
      rescue ArgumentError => ex
        return error(ex.message, 400)
      end

      success(software_license_policy: software_license_policy)
    end
  end
end
