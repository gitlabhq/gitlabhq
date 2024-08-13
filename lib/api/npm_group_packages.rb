# frozen_string_literal: true

module API
  class NpmGroupPackages < ::API::Base
    feature_category :package_registry
    urgency :low

    helpers do
      include Gitlab::Utils::StrongMemoize

      def group_or_namespace
        group = find_group(params[:id])
        check_group_access(group)
      end
      strong_memoize_attr :group_or_namespace
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/-/packages/npm' do
        include ::API::Concerns::Packages::NpmEndpoints
        include ::API::Concerns::Packages::NpmNamespaceEndpoints
      end
    end
  end
end
