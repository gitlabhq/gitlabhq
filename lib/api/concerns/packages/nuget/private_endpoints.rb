# frozen_string_literal: true

#
# NuGet Package Manager Client API
#
# These API endpoints are not consumed directly by users, so there is no documentation for the
# individual endpoints. They are called by the NuGet package manager client when users run commands
# like `nuget install` or `nuget push`. The usage of the GitLab NuGet registry is documented here:
# https://docs.gitlab.com/ee/user/packages/nuget_repository/
#
# Technical debt: https://gitlab.com/gitlab-org/gitlab/issues/35798
module API
  module Concerns
    module Packages
      module Nuget
        module PrivateEndpoints
          extend ActiveSupport::Concern

          POSITIVE_INTEGER_REGEX = %r{\A[1-9]\d*\z}
          NON_NEGATIVE_INTEGER_REGEX = %r{\A(0|[1-9]\d*)\z}

          included do
            # https://docs.microsoft.com/en-us/nuget/api/registration-base-url-resource
            params do
              requires :package_name, type: String, desc: 'The NuGet package name',
                regexp: API::NO_SLASH_URL_PART_REGEX, documentation: { example: 'MyNuGetPkg' }
            end
            namespace '/metadata/*package_name' do
              after_validation do
                authorize_packages_access!(project_or_group, required_permission)
              end

              desc 'The NuGet Metadata Service - Package name level' do
                detail 'This feature was introduced in GitLab 12.8'
                success code: 200, model: ::API::Entities::Nuget::PackagesMetadata
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[nuget_packages]
              end
              get 'index', format: :json, urgency: :low do
                present ::Packages::Nuget::PackagesMetadataPresenter.new(find_packages),
                  with: ::API::Entities::Nuget::PackagesMetadata
              end

              desc 'The NuGet Metadata Service - Package name and version level' do
                detail 'This feature was introduced in GitLab 12.8'
                success code: 200, model: ::API::Entities::Nuget::PackageMetadata
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[nuget_packages]
              end
              params do
                requires :package_version, type: String, desc: 'The NuGet package version',
                  regexp: API::NO_SLASH_URL_PART_REGEX, documentation: { example: '1.0.0' }
              end
              get '*package_version', format: :json, urgency: :low do
                present ::Packages::Nuget::PackageMetadataPresenter.new(find_package),
                  with: ::API::Entities::Nuget::PackageMetadata
              end
            end

            # https://docs.microsoft.com/en-us/nuget/api/search-query-service-resource
            params do
              optional :q, type: String, desc: 'The search term', documentation: { example: 'MyNuGet' }
              optional :skip, type: Integer, desc: 'The number of results to skip', default: 0,
                regexp: NON_NEGATIVE_INTEGER_REGEX, documentation: { example: 1 }
              optional :take, type: Integer, desc: 'The number of results to return',
                default: Kaminari.config.default_per_page, regexp: POSITIVE_INTEGER_REGEX, documentation: { example: 1 }
              optional :prerelease, type: ::Grape::API::Boolean, desc: 'Include prerelease versions', default: true
            end
            namespace '/query' do
              after_validation do
                authorize_packages_access!(project_or_group, required_permission)
              end

              desc 'The NuGet Search Service' do
                detail 'This feature was introduced in GitLab 12.8'
                success code: 200, model: ::API::Entities::Nuget::SearchResults
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[nuget_packages]
              end
              get format: :json, urgency: :low do
                track_package_event(
                  'search_package',
                  :nuget,
                  **snowplow_gitlab_standard_context.merge(category: 'API::NugetPackages')
                )

                present ::Packages::Nuget::SearchResultsPresenter.new(search_packages),
                  with: ::API::Entities::Nuget::SearchResults
              end
            end
          end
        end
      end
    end
  end
end
