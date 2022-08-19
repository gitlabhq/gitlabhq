# frozen_string_literal: true

module Packages
  module Policies
    class ProjectPolicy < BasePolicy
      delegate(:project) { @subject.project }

      overrides(:read_package)

      rule { anonymous & ~project.public_project }.prevent_all

      rule { ~project.public_project & ~project.internal_access & ~project.project_allowed_for_job_token }.prevent_all

      rule { project.packages_disabled }.policy do
        prevent(:read_package)
      end

      rule { can?(:reporter_access) }.policy do
        enable :read_package
      end

      rule { can?(:public_access) }.policy do
        enable :read_package
      end

      rule { project.read_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { project.write_package_registry_deploy_token }.policy do
        enable :read_package
      end
    end
  end
end
