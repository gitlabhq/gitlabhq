# frozen_string_literal: true

###
# API endpoints for the RubyGem package registry
module API
  class RubygemPackages < ::API::Base
    include ::API::Helpers::Authentication
    helpers ::API::Helpers::PackagesHelpers

    feature_category :package_registry

    # The Marshal version can be found by "#{Marshal::MAJOR_VERSION}.#{Marshal::MINOR_VERSION}"
    # Updating the version should require a GitLab API version change.
    MARSHAL_VERSION = '4.8'

    FILE_NAME_REQUIREMENTS = {
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    content_type :binary, 'application/octet-stream'

    authenticate_with do |accept|
      accept.token_types(:personal_access_token, :deploy_token, :job_token)
            .sent_through(:http_token)
    end

    before do
      require_packages_enabled!
      authenticate!
      not_found! unless Feature.enabled?(:rubygem_packages, user_project)
    end

    params do
      requires :id, type: String, desc: 'The ID or full path of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/rubygems' do
        desc 'Download the spec index file' do
          detail 'This feature was introduced in GitLab 13.9'
        end
        params do
          requires :file_name, type: String, desc: 'Spec file name'
        end
        get ":file_name", requirements: FILE_NAME_REQUIREMENTS do
          # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299267
          not_found!
        end

        desc 'Download the gemspec file' do
          detail 'This feature was introduced in GitLab 13.9'
        end
        params do
          requires :file_name, type: String, desc: 'Gemspec file name'
        end
        get "quick/Marshal.#{MARSHAL_VERSION}/:file_name", requirements: FILE_NAME_REQUIREMENTS do
          # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299284
          not_found!
        end

        desc 'Download the .gem package' do
          detail 'This feature was introduced in GitLab 13.9'
        end
        params do
          requires :file_name, type: String, desc: 'Package file name'
        end
        get "gems/:file_name", requirements: FILE_NAME_REQUIREMENTS do
          # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299283
          not_found!
        end

        namespace 'api/v1' do
          desc 'Authorize a gem upload from workhorse' do
            detail 'This feature was introduced in GitLab 13.9'
          end
          post 'gems/authorize' do
            # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299263
            not_found!
          end

          desc 'Upload a gem' do
            detail 'This feature was introduced in GitLab 13.9'
          end
          post 'gems' do
            # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299263
            not_found!
          end

          desc 'Fetch a list of dependencies' do
            detail 'This feature was introduced in GitLab 13.9'
          end
          params do
            optional :gems, type: String, desc: 'Comma delimited gem names'
          end
          get 'dependencies' do
            # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/299282
            not_found!
          end
        end
      end
    end
  end
end
