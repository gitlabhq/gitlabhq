# frozen_string_literal: true

module API
  class ProjectPackagesProtectionRules < ::API::Base
    feature_category :package_registry
    helpers ::API::Helpers::PackagesHelpers

    before do
      if Feature.disabled?(:packages_protected_packages, user_project)
        render_api_error!("'packages_protected_packages' feature flag is disabled", :not_found)
      end

      authenticate!
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Delete package protection rule' do
        success code: 204, message: '204 No Content'
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[projects]
      end
      params do
        requires :package_protection_rule_id, type: Integer, desc: 'The ID of the package protection rule'
      end
      delete ':id/packages/protection/rules/:package_protection_rule_id' do
        authorize_admin_package!

        package_protection_rule = user_project.package_protection_rules.find(params[:package_protection_rule_id])

        destroy_conditionally!(package_protection_rule) do |package_protection_rule|
          response = ::Packages::Protection::DeleteRuleService.new(package_protection_rule,
            current_user: current_user).execute

          render_api_error!({ error: response.message }, :bad_request) if response.error?
        end
      end
    end
  end
end
