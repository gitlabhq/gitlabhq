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
            end

            namespace 'users' do
              before do
                authenticate!
              end

              format :txt
              content_type :txt, 'text/plain'

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
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
            route_setting :authorization, skip_job_token_policies: true

            get 'conans/search', urgency: :low do
              response = ::Packages::Conan::SearchService.new(search_project, current_user, query: params[:q]).execute
              bad_request!(response.message) if response.error?

              response.payload
            end
          end
        end
      end
    end
  end
end
