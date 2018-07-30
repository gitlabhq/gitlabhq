# frozen_string_literal: true

# Managed license creation service. For use in the managed license controller.
module SoftwareLicensePolicies
  class CreateService < ::BaseService
    def initialize(project, user, params)
      super(project, user, params.with_indifferent_access)
    end

    # Returns the created managed license.
    def execute
      return error("", 403) unless can?(@current_user, :admin_software_license_policy, @project)

      # Load or create the software license
      name = params.delete(:name)

      software_license = SoftwareLicense.transaction do
        begin
          SoftwareLicense.transaction(requires_new: true) do
            SoftwareLicense.find_or_create_by(name: name)
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      # Add the software license to params
      params[:software_license] = software_license

      begin
        software_license_policy = @project.software_license_policies.create(params)
      rescue ArgumentError => ex
        return error(ex.message, 400)
      end

      if software_license_policy.errors.any?
        return error(software_license_policy.errors.full_messages.join("\n"), 400)
      end

      success(software_license_policy: software_license_policy)
    end
  end
end
