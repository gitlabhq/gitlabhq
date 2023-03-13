# frozen_string_literal: true
module API
  class RpmProjectPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Authentication

    feature_category :package_registry

    before do
      require_packages_enabled!

      not_found! unless ::Feature.enabled?(:rpm_packages, authorized_user_project)

      authorize_read_package!(authorized_user_project)
    end

    authenticate_with do |accept|
      accept.token_types(:personal_access_token_with_username, :deploy_token_with_username, :job_token_with_username)
            .sent_through(:http_basic_auth)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/rpm' do
        desc 'Download repository metadata files' do
          detail 'This feature was introduced in GitLab 15.7'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[rpm_packages]
        end
        params do
          requires :file_name, type: String, desc: 'Repository metadata file name'
        end
        get 'repodata/*file_name', requirements: { file_name: API::NO_SLASH_URL_PART_REGEX } do
          authorize_read_package!(authorized_user_project)

          repository_file = Packages::Rpm::RepositoryFile.find_by_project_id_and_file_name!(
            authorized_user_project.id,
            "#{params['file_name']}.#{params['format']}"
          )

          present_carrierwave_file!(repository_file.file)
        end

        desc 'Download RPM package files' do
          detail 'This feature was introduced in GitLab 15.7'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[rpm_packages]
        end
        params do
          requires :package_file_id, type: Integer, desc: 'RPM package file id'
          requires :file_name, type: String, desc: 'RPM package file name'
        end
        get '*package_file_id/*file_name', requirements: { file_name: API::NO_SLASH_URL_PART_REGEX } do
          track_package_event(
            'pull_package',
            :rpm,
            category: self.class.name,
            project: authorized_user_project,
            namespace: authorized_user_project.namespace
          )
          not_found!
        end

        desc 'Upload a RPM package' do
          detail 'This feature was introduced in GitLab 15.7'
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[rpm_packages]
        end
        post do
          authorize_create_package!(authorized_user_project)

          if authorized_user_project.actual_limits.exceeded?(:rpm_max_file_size, params[:file].size)
            bad_request!('File is too large')
          end

          if Packages::Rpm::RepositoryFile.has_oversized_filelists?(project_id: authorized_user_project.id)
            bad_request!('Repository packages limit exceeded')
          end

          track_package_event(
            'push_package',
            :rpm,
            category: self.class.name,
            project: authorized_user_project,
            namespace: authorized_user_project.namespace
          )

          not_found!
        end

        desc 'Authorize package upload from workhorse' do
          detail 'This feature was introduced in GitLab 15.7'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[rpm_packages]
        end
        post 'authorize' do
          not_found!
        end
      end
    end
  end
end
