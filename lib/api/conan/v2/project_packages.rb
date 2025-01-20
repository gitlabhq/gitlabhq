# frozen_string_literal: true

module API
  module Conan
    module V2
      class ProjectPackages < ::API::Base
        before do
          if Feature.disabled?(:conan_package_revisions_support, Feature.current_request)
            render_api_error!("'conan_package_revisions_support' feature flag is disabled", :not_found)
          end
        end

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          namespace ':id/packages/conan/v2' do
            include ::API::Concerns::Packages::Conan::SharedEndpoints
            params do
              with(type: String) do
                requires :package_name, regexp: PACKAGE_COMPONENT_REGEX,
                  desc: 'Package name', documentation: { example: 'my-package' }
                requires :package_version, regexp: PACKAGE_COMPONENT_REGEX,
                  desc: 'Package version', documentation: { example: '1.0' }
                requires :package_username, regexp: CONAN_REVISION_USER_CHANNEL_REGEX,
                  desc: 'Package username', documentation: { example: 'my-group+my-project' }
                requires :package_channel, regexp: CONAN_REVISION_USER_CHANNEL_REGEX,
                  desc: 'Package channel', documentation: { example: 'stable' }
              end
            end
            namespace 'conans/:package_name/:package_version/:package_username/:package_channel',
              requirements: PACKAGE_REQUIREMENTS do
              after_validation do
                check_username_channel
              end

              desc 'Download recipe files' do
                detail 'This feature was introduced in GitLab 17.8'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
                hidden true
              end

              params do
                with(type: String) do
                  requires :recipe_revision, regexp: Gitlab::Regex.conan_revision_regex_v2,
                    desc: 'Recipe revision', documentation: { example: 'df28fd816be3a119de5ce4d374436b25' }
                  requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES,
                    documentation: { example: 'conanfile.py' }
                end
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages

              get 'revisions/:recipe_revision/files/:file_name', requirements: FILE_NAME_REQUIREMENTS do
                authorize_job_token_policies!(project)

                render_api_error!('Not supported', :not_found)
              end
            end
          end
        end
      end
    end
  end
end
