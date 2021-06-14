# frozen_string_literal: true

module API
  class ProjectDebianDistributions < ::API::Base
    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      rescue_from ArgumentError do |e|
        render_api_error!(e.message, 400)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_api_error!(e.message, 400)
      end

      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:debian_packages, user_project)

        authorize_read_package!
      end

      namespace ':id' do
        helpers do
          def project_or_group
            user_project
          end
        end

        include ::API::Concerns::Packages::DebianDistributionEndpoints
      end
    end
  end
end
