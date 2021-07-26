# frozen_string_literal: true

module API
  class GroupDebianDistributions < ::API::Base
    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      rescue_from ArgumentError do |e|
        render_api_error!(e.message, 400)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_api_error!(e.message, 400)
      end

      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:debian_group_packages, user_group)
      end

      namespace ':id/-' do
        helpers do
          def project_or_group
            user_group
          end
        end

        include ::API::Concerns::Packages::DebianDistributionEndpoints
      end
    end
  end
end
