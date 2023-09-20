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

      def group_or_namespace
        group
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/-/packages/npm' do
        include ::API::Concerns::Packages::NpmEndpoints
      end
    end
  end
end
