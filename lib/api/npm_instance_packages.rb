# frozen_string_literal: true
module API
  class NpmInstancePackages < ::API::Base
    feature_category :package_registry
    urgency :low

    helpers do
      def group_or_namespace
        namespace_path = ::Packages::Npm.scope_of(params[:package_name])
        return unless namespace_path

        Namespace.top_level.by_path(namespace_path)
      end
    end

    namespace 'packages/npm' do
      include ::API::Concerns::Packages::NpmEndpoints
      include ::API::Concerns::Packages::NpmNamespaceEndpoints
    end
  end
end
