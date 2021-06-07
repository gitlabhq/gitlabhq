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
    include ::API::Helpers::Authentication

    feature_category :package_registry

    default_format :json

    authenticate_with do |accept|
      accept.token_types(:personal_access_token_with_username, :deploy_token_with_username, :job_token_with_username)
            .sent_through(:http_basic_auth)
    end

    rescue_from ArgumentError do |e|
      render_api_error!(e.message, 400)
    end

    after_validation do
      require_packages_enabled!
    end

    helpers do
      def project_or_group
        find_authorized_group!
      end

      def require_authenticated!
        unauthorized! unless current_user
      end

      def snowplow_gitlab_standard_context
        { namespace: find_authorized_group! }
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group', regexp: ::API::Concerns::Packages::NugetEndpoints::POSITIVE_INTEGER_REGEX
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/-/packages/nuget' do
        after_validation do
          # This API can't be accessed anonymously
          require_authenticated!
        end

        include ::API::Concerns::Packages::NugetEndpoints
      end
    end
  end
end
