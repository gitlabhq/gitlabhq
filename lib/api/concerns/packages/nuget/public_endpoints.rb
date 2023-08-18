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
            desc 'The NuGet V3 Feed Service Index' do
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

            desc 'The NuGet V2 Feed Service Index' do
              detail 'This feature was introduced in GitLab 16.2'
              success code: 200
              failure [
                { code: 404, message: 'Not Found' }
              ]
              tags %w[nuget_packages]
            end
            namespace '/v2' do
              get format: :xml, urgency: :low do
                env['api.format'] = :xml
                content_type 'application/xml; charset=utf-8'
                # needed to allow browser default inline styles in xml response
                header 'Content-Security-Policy', "nonce-#{SecureRandom.base64(16)}"

                track_package_event(
                  'cli_metadata',
                  :nuget,
                  **snowplow_gitlab_standard_context_without_auth.merge(category: 'API::NugetPackages', feed: 'v2')
                )

                present ::Packages::Nuget::V2::ServiceIndexPresenter
                          .new(project_or_group_without_auth)
                          .xml
              end

              # https://www.nuget.org/api/v2/$metadata
              desc 'The NuGet V2 Feed Package $metadata endpoint' do
                detail 'This feature was introduced in GitLab 16.3'
                success code: 200
                tags %w[nuget_packages]
              end

              get '$metadata', format: :xml, urgency: :low do
                env['api.format'] = :xml
                content_type 'application/xml; charset=utf-8'
                # needed to allow browser default inline styles in xml response
                header 'Content-Security-Policy', "nonce-#{SecureRandom.base64(16)}"

                present ::Packages::Nuget::V2::MetadataIndexPresenter.new.xml
              end
            end
          end
        end
      end
    end
  end
end
