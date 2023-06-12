# frozen_string_literal: true

# NuGet Package Manager Client API

# These API endpoints are not consumed directly by users, so there is no documentation for the
# individual endpoints. They are called by the NuGet package manager client when users run commands
# like `nuget install` or `nuget push`. The usage of the GitLab NuGet registry is documented here:
# https://docs.gitlab.com/ee/user/packages/nuget_repository/

module API
  module Concerns
    module Packages
      module Nuget
        module PublicEndpoints
          extend ActiveSupport::Concern

          included do
            # https://docs.microsoft.com/en-us/nuget/api/service-index
            desc 'The NuGet Service Index' do
              detail 'This feature was introduced in GitLab 12.6'
              success code: 200, model: ::API::Entities::Nuget::ServiceIndex
              failure [
                { code: 404, message: 'Not Found' }
              ]
              tags %w[nuget_packages]
            end
            get 'index', format: :json, urgency: :default do
              track_package_event(
                'cli_metadata',
                :nuget,
                **snowplow_gitlab_standard_context_without_auth.merge(category: 'API::NugetPackages')
              )

              present ::Packages::Nuget::ServiceIndexPresenter.new(project_or_group_without_auth),
                with: ::API::Entities::Nuget::ServiceIndex
            end
          end
        end
      end
    end
  end
end
