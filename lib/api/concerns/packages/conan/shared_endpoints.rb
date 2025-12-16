# frozen_string_literal: true

# Conan Package Manager Client API
#
# These API endpoints are not consumed directly by users, so there is no documentation for the
# individual endpoints. They are called by the Conan package manager client when users run commands
# like `conan install` or `conan upload`. The usage of the GitLab Conan repository is documented here:
# https://docs.gitlab.com/ee/user/packages/conan_repository/#installing-a-package
#
# Technical debt: https://gitlab.com/gitlab-org/gitlab/issues/35798
module API
  module Concerns
    module Packages
      module Conan
        module SharedEndpoints
          extend ActiveSupport::Concern

          PACKAGE_REQUIREMENTS = {
            package_name: API::NO_SLASH_URL_PART_REGEX,
            package_version: API::NO_SLASH_URL_PART_REGEX,
            package_username: API::NO_SLASH_URL_PART_REGEX,
            package_channel: API::NO_SLASH_URL_PART_REGEX
          }.freeze

          FILE_NAME_REQUIREMENTS = {
            file_name: API::NO_SLASH_URL_PART_REGEX
          }.freeze

          PACKAGE_COMPONENT_REGEX = Gitlab::Regex.conan_recipe_component_regex
          CONAN_REVISION_USER_CHANNEL_REGEX = Gitlab::Regex.conan_recipe_user_channel_regex

          CONAN_FILES = (Gitlab::Regex::Packages::CONAN_RECIPE_FILES +
            Gitlab::Regex::Packages::CONAN_PACKAGE_FILES).uniq.freeze

          included do
            feature_category :package_registry

            helpers ::API::Helpers::PackagesManagerClientsHelpers
            helpers ::API::Helpers::Packages::Conan::ApiHelpers
            helpers ::API::Helpers::RelatedResourcesHelpers

            rescue_from ActiveRecord::RecordInvalid do |e|
              render_api_error!(e.message, 400)
            end

            before do
              not_found! if Gitlab::FIPS.enabled?
              require_packages_enabled!
              authenticate_non_get!
            end

            namespace 'users' do
              before do
                authenticate!
              end

              format :txt
              content_type :txt, 'text/plain'

              desc 'Authenticate user against conan CLI' do
                detail 'This feature was introduced in GitLab 12.2'
                success code: 200
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, skip_job_token_policies: true

              get 'authenticate', urgency: :low do
                unauthorized! unless token

                token.to_jwt
              end

              desc 'Check for valid user credentials per conan CLI' do
                detail 'This feature was introduced in GitLab 12.4'
                success code: 200
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, skip_job_token_policies: true

              get 'check_credentials', urgency: :default do
                :ok
              end
            end

            namespace 'conans' do
              desc 'Search for packages' do
                detail 'This feature was introduced in GitLab 12.4'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              params do
                requires :q, type: String, desc: 'Search query', documentation: { example: 'Hello*' }
                optional :ignorecase, type: ::Grape::API::Boolean,
                  desc: 'Ignore case when searching (case-insensitive search)',
                  documentation: { example: 'False' }
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, skip_job_token_policies: true

              get 'search', urgency: :low do
                response = ::Packages::Conan::SearchService.new(
                  search_project,
                  current_user,
                  query: params[:q],
                  ignorecase: params[:ignorecase]
                ).execute
                bad_request!(response.message) if response.error?

                response.payload
              end

              params do
                with(regexp: PACKAGE_COMPONENT_REGEX) do
                  requires :package_name, type: String, desc: 'Package name', documentation: { example: 'my-package' }
                  requires :package_version, type: String, desc: 'Package version', documentation: { example: '1.0' }
                end
                with(regexp: CONAN_REVISION_USER_CHANNEL_REGEX) do
                  requires :package_username, type: String, desc: 'Package username',
                    documentation: { example: 'my-group+my-project' }
                  requires :package_channel, type: String, desc: 'Package channel', documentation: { example: 'stable' }
                end
              end

              namespace ':package_name/:package_version/:package_username/:package_channel/search',
                requirements: PACKAGE_REQUIREMENTS do
                desc 'Get package references metadata' do
                  detail 'This feature was introduced in GitLab 18.0'
                  success code: 200
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[conan_packages]
                end

                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization,  job_token_policies: :read_packages,
                  allow_public_access_for_enabled_project_features: :package_registry

                get urgency: :low do
                  check_username_channel

                  authorize_read_package!(project)
                  not_found!('Package') unless package

                  package.conan_package_references.pluck_reference_and_info.to_h
                end
              end
            end
          end
        end
      end
    end
  end
end
