# frozen_string_literal: true
module API
  class NpmInstancePackages < ::API::Base
    helpers ::API::Helpers::Packages::Npm

    feature_category :package_registry
    urgency :low

    helpers do
      def endpoint_scope
        :instance
      end

      def group_or_namespace
        top_namespace_from(params[:package_name])
      end
    end

    namespace 'packages/npm' do
      include ::API::Concerns::Packages::NpmEndpoints
    end
  end
end
