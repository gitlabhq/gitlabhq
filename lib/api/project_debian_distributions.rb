# frozen_string_literal: true

module API
  class ProjectDebianDistributions < ::API::Base
    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:debian_packages, project_or_group)
      end

      namespace ':id' do
        helpers do
          def project_or_group(action = :read_package)
            user_project(action: action)
          end
        end

        include ::API::Concerns::Packages::DebianDistributionEndpoints
      end
    end
  end
end
