# frozen_string_literal: true

module API
  class ManagedLicenses < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      # Make the software license policy specified by id in the request available
      def software_license_policy
        id = params[:managed_license_id]
        @software_license_policy ||= SoftwareLicensePoliciesFinder.new(current_user, user_project).find_by_name_or_id(id)
      end

      def authorize_can_read!
        authorize!(:read_software_license_policy, user_project)
      end

      def authorize_can_admin!
        authorize!(:admin_software_license_policy, user_project)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS  do
      desc 'Get project software license policies' do
        success Entities::ManagedLicense
      end
      params do
        use :pagination
      end
      get ':id/managed_licenses' do
        authorize_can_read!

        software_license_policies = user_project.software_license_policies
        present paginate(software_license_policies), with: Entities::ManagedLicense
      end

      desc 'Get a specific software license policy from a project' do
        success Entities::ManagedLicense
      end
      get ':id/managed_licenses/:managed_license_id', requirements: { managed_license_id: /.*/ } do
        authorize_can_read!
        break not_found!('SoftwareLicensePolicy') unless software_license_policy

        present software_license_policy, with: Entities::ManagedLicense
      end

      desc 'Create a new software license policy in a project' do
        success Entities::ManagedLicense
      end
      params do
        requires :name, type: String, desc: 'The name of the license'
        requires :approval_status,
          type: String,
          values: %w(approved blacklisted),
          desc: 'The approval status of the license. "blacklisted" or "approved".'
      end
      post ':id/managed_licenses' do
        authorize_can_admin!

        result = SoftwareLicensePolicies::CreateService.new(
          user_project,
          current_user,
          declared_params(include_missing: false)
        ).execute
        created_software_license_policy = result[:software_license_policy]

        if result[:status] == :success
          present created_software_license_policy, with: Entities::ManagedLicense
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Update an existing software license policy from a project' do
        success Entities::ManagedLicense
      end
      params do
        optional :name, type: String, desc: 'The name of the license'
        optional :approval_status,
          type: String,
          values: %w(approved blacklisted),
          desc: 'The approval status of the license. "blacklisted" or "approved".'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      patch ':id/managed_licenses/:managed_license_id', requirements: { managed_license_id: /.*/ } do
        authorize_can_admin!
        break not_found!('SoftwareLicensePolicy') unless software_license_policy

        result = SoftwareLicensePolicies::UpdateService.new(
          user_project,
          current_user,
          declared_params(include_missing: false).except(:id, :name)
        ).execute(@software_license_policy)

        if result[:status] == :success
          present @software_license_policy, with: Entities::ManagedLicense
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete an existing software license policy from a project' do
        success Entities::ManagedLicense
      end
      delete ':id/managed_licenses/:managed_license_id', requirements: { managed_license_id: /.*/ } do
        authorize_can_admin!
        not_found!('SoftwareLicensePolicy') unless software_license_policy

        status 204
        software_license_policy.destroy!
      end
    end
  end
end
