# frozen_string_literal: true
module API
  class MavenPackages < ::API::Base
    MAVEN_ENDPOINT_REQUIREMENTS = {
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    feature_category :package_registry

    content_type :md5, 'text/plain'
    content_type :sha1, 'text/plain'
    content_type :binary, 'application/octet-stream'

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    before do
      require_packages_enabled!
      authenticate_non_get!
    end

    helpers ::API::Helpers::PackagesHelpers

    helpers do
      def path_exists?(path)
        return false if path.blank?

        Packages::Maven::Metadatum.with_path(path)
                                  .exists?
      end

      def extract_format(file_name)
        name, _, format = file_name.rpartition('.')

        if %w(md5 sha1).include?(format)
          [name, format]
        else
          [file_name, format]
        end
      end

      def verify_package_file(package_file, uploaded_file)
        stored_sha256 = Digest::SHA256.hexdigest(package_file.file_sha1)
        expected_sha256 = uploaded_file.sha256

        if stored_sha256 == expected_sha256
          no_content!
        else
          conflict!
        end
      end

      def find_project_by_path(path)
        project_path = path.rpartition('/').first
        Project.find_by_full_path(project_path)
      end

      def jar_file?(format)
        format == 'jar'
      end

      def present_carrierwave_file_with_head_support!(file, supports_direct_download: true)
        if head_request_on_aws_file?(file, supports_direct_download) && !file.file_storage?
          return redirect(signed_head_url(file))
        end

        present_carrierwave_file!(file, supports_direct_download: supports_direct_download)
      end

      def signed_head_url(file)
        fog_storage = ::Fog::Storage.new(file.fog_credentials)
        fog_dir = fog_storage.directories.new(key: file.fog_directory)
        fog_file = fog_dir.files.new(key: file.path)
        expire_at = ::Fog::Time.now + file.fog_authenticated_url_expiration

        fog_file.collection.head_url(fog_file.key, expire_at)
      end

      def head_request_on_aws_file?(file, supports_direct_download)
        Gitlab.config.packages.object_store.enabled &&
          supports_direct_download &&
          file.class.direct_download_enabled? &&
          request.head? &&
          file.fog_credentials[:provider] == 'AWS'
      end

      def fetch_package(file_name:, project: nil, group: nil)
        order_by_package_file = file_name.include?(::Packages::Maven::Metadata.filename) &&
                                  !params[:path].include?(::Packages::Maven::FindOrCreatePackageService::SNAPSHOT_TERM)

        ::Packages::Maven::PackageFinder.new(
          current_user,
          project || group,
          path: params[:path],
          order_by_package_file: order_by_package_file
        ).execute!
      end
    end

    desc 'Download the maven package file at instance level' do
      detail 'This feature was introduced in GitLab 11.6'
    end
    params do
      requires :path, type: String, desc: 'Package path'
      requires :file_name, type: String, desc: 'Package file name'
    end
    route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
    get 'packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
      # return a similar failure to authorize_read_package!(project)
      forbidden! unless path_exists?(params[:path])

      file_name, format = extract_format(params[:file_name])

      # To avoid name collision we require project path and project package be the same.
      # For packages that have different name from the project we should use
      # the endpoint that includes project id
      project = find_project_by_path(params[:path])

      authorize_read_package!(project)

      package = fetch_package(file_name: file_name, project: project)

      package_file = ::Packages::PackageFileFinder
        .new(package, file_name).execute!

      case format
      when 'md5'
        package_file.file_md5
      when 'sha1'
        package_file.file_sha1
      else
        track_package_event('pull_package', :maven, project: project, namespace: project.namespace) if jar_file?(format)
        present_carrierwave_file_with_head_support!(package_file.file)
      end
    end

    desc 'Download the maven package file at a group level' do
      detail 'This feature was introduced in GitLab 11.7'
    end
    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name'
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      get ':id/-/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        # return a similar failure to group = find_group(params[:id])
        not_found!('Group') unless path_exists?(params[:path])

        file_name, format = extract_format(params[:file_name])

        group = find_group(params[:id])

        not_found!('Group') unless can?(current_user, :read_group, group)

        package = fetch_package(file_name: file_name, group: group)

        authorize_read_package!(package.project)

        package_file = ::Packages::PackageFileFinder
          .new(package, file_name).execute!

        case format
        when 'md5'
          package_file.file_md5
        when 'sha1'
          package_file.file_sha1
        else
          track_package_event('pull_package', :maven, project: package.project, namespace: package.project.namespace) if jar_file?(format)

          present_carrierwave_file_with_head_support!(package_file.file)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name'
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      get ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        # return a similar failure to user_project
        not_found!('Project') unless path_exists?(params[:path])

        authorize_read_package!(user_project)

        file_name, format = extract_format(params[:file_name])

        package = fetch_package(file_name: file_name, project: user_project)

        package_file = ::Packages::PackageFileFinder
          .new(package, file_name).execute!

        case format
        when 'md5'
          package_file.file_md5
        when 'sha1'
          package_file.file_sha1
        else
          track_package_event('pull_package', :maven, project: user_project, namespace: user_project.namespace) if jar_file?(format)

          present_carrierwave_file_with_head_support!(package_file.file)
        end
      end

      desc 'Workhorse authorize the maven package file upload' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name', regexp: Gitlab::Regex.maven_file_name_regex
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      put ':id/packages/maven/*path/:file_name/authorize', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        authorize_upload!

        status 200
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
        ::Packages::PackageFileUploader.workhorse_authorize(has_length: true, maximum_size: user_project.actual_limits.maven_max_file_size)
      end

      desc 'Upload the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      params do
        requires :path, type: String, desc: 'Package path'
        requires :file_name, type: String, desc: 'Package file name', regexp: Gitlab::Regex.maven_file_name_regex
        requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)'
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      put ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        authorize_upload!
        bad_request!('File is too large') if user_project.actual_limits.exceeded?(:maven_max_file_size, params[:file].size)

        file_name, format = extract_format(params[:file_name])

        result = ::Packages::Maven::FindOrCreatePackageService
          .new(user_project, current_user, params.merge(build: current_authenticated_job)).execute

        bad_request!(result.errors.first) if result.error?

        package = result.payload[:package]

        case format
        when 'sha1'
          # After uploading a file, Maven tries to upload a sha1 and md5 version of it.
          # Since we store md5/sha1 in database we simply need to validate our hash
          # against one uploaded by Maven. We do this for `sha1` format.
          package_file = ::Packages::PackageFileFinder
            .new(package, file_name).execute!

          verify_package_file(package_file, params[:file])
        when 'md5'
          ''
        else
          track_package_event('push_package', :maven, user: current_user, project: user_project, namespace: user_project.namespace) if jar_file?(format)

          file_params = {
            file:      params[:file],
            size:      params['file.size'],
            file_name: file_name,
            file_type: params['file.type'],
            file_sha1: params['file.sha1'],
            file_md5:  params['file.md5']
          }

          ::Packages::CreatePackageFileService.new(package, file_params.merge(build: current_authenticated_job)).execute
        end
      end
    end
  end
end
