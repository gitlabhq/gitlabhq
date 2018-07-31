# frozen_string_literal: true

class SoftwareLicensePoliciesFinder
  include Gitlab::Allowable
  include FinderMethods

  attr_accessor :current_user, :project

  def initialize(current_user, project)
    @current_user = current_user
    @project = project
  end

  def find_by_name_or_id(id)
    return nil unless can?(current_user, :read_software_license_policy, project)

    software_licenses = SoftwareLicense.arel_table
    software_license_policies = SoftwareLicensePolicy.arel_table
    project.software_license_policies.joins(:software_license).where(
      software_licenses[:name].eq(id).or(software_license_policies[:id].eq(id))
    ).take
  end
end
