# frozen_string_literal: true

# NuGet Package Manager Client API
#
# These API endpoints are not meant to be consumed directly by users. They are
# called by the NuGet package manager client when users run commands
# like `nuget install` or `nuget push`.
#
# This is the group level API.
module API
  class NugetGroupPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    helpers ::API::Helpers::Packages::Nuget
    include ::API::Helpers::Authentication

    feature_category :package_registry

    default_format :json

    rescue_from ArgumentError do |e|
      render_api_error!(e.message, 400)
    end

    after_validation do
      require_packages_enabled!
    end

    helpers do
      include ::Gitlab::Utils::StrongMemoize

      def project_or_group
        find_authorized_group!(action: required_permission)
      end

      def project_or_group_without_auth
        find_group(params[:id]).presence || not_found!
      end
      strong_memoize_attr :project_or_group_without_auth

      def symbol_server_enabled?
        project_or_group_without_auth.package_settings.nuget_symbol_server_enabled
      end

      def snowplow_gitlab_standard_context
        { namespace: project_or_group }
      end

      def snowplow_gitlab_standard_context_without_auth
        { namespace: project_or_group_without_auth }
      end

      def required_permission
        :read_package_within_public_registries
      end
    end

    params do
      requires :id, types: [Integer, String], desc: 'The group ID or full group path.',
        regexp: ::API::Concerns::Packages::Nuget::PrivateEndpoints::POSITIVE_INTEGER_REGEX
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/-/packages' do
        namespace '/nuget' do
          include ::API::Concerns::Packages::Nuget::PublicEndpoints
        end

        authenticate_with do |accept|
          accept.token_types(
            :personal_access_token_with_username,
            :deploy_token_with_username,
            :job_token_with_username
          ).sent_through(:http_basic_auth)
        end

        namespace '/nuget' do
          after_validation do
            # This API can't be accessed anonymously
            authenticate!
          end

          include ::API::Concerns::Packages::Nuget::PrivateEndpoints
        end
      end
    end
  end
end
