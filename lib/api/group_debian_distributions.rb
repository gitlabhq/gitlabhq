# frozen_string_literal: true

module API
  class GroupDebianDistributions < ::API::Base
    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:debian_group_packages, user_group)
      end

      namespace ':id/-' do
        helpers do
          def project_or_group(_ = nil)
            user_group
          end
        end

        include ::API::Concerns::Packages::DebianDistributionEndpoints
      end
    end
  end
end
