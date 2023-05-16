# frozen_string_literal: true

module API
  class NpmGroupPackages < ::API::Base
    helpers ::API::Helpers::Packages::Npm

    feature_category :package_registry
    urgency :low

    helpers do
      def endpoint_scope
        :group
      end
    end

    after_validation do
      not_found! unless Feature.enabled?(:npm_group_level_endpoints, group)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/-/packages/npm' do
        params do
          requires :package_name, type: String, desc: 'Package name'
        end
        namespace '-/package/*package_name' do
          get 'dist-tags', format: false do
            not_found!
          end

          namespace 'dist-tags/:tag' do
            put format: false do
              not_found!
            end

            delete format: false do
              not_found!
            end
          end
        end

        post '-/npm/v1/security/audits/quick' do
          not_found!
        end

        post '-/npm/v1/security/advisories/bulk' do
          not_found!
        end

        include ::API::Concerns::Packages::NpmEndpoints
      end
    end
  end
end
