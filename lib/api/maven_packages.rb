# frozen_string_literal: true
module API
  class MavenPackages < ::API::Base
    MAVEN_ENDPOINT_REQUIREMENTS = {
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    feature_category :package_registry
    urgency :low

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
    helpers ::API::Helpers::Packages::DependencyProxyHelpers

    helpers do
      def path_exists?(path)
        return false if path.blank?

        Packages::Maven::Metadatum.with_path(path)
                                  .exists?
      end

      def extract_format(file_name)
        name, _, format = file_name.rpartition('.')

        if %w(md5 sha1).include?(format)
          unprocessable_entity! if Gitlab::FIPS.enabled? && format == 'md5'

          [name, format]
        else
          [file_name, format]
        end
      end

      # The sha verification done by the maven api is between:
      # - the sha256 set by workhorse helpers
      # - the sha256 of the sha1 of the uploaded package file
      def verify_package_file(package_file, uploaded_file)
        stored_sha256 = Digest::SHA256.hexdigest(package_file.file_sha1)
        expected_sha256 = uploaded_file.sha256

        if stored_sha256 == expected_sha256
          no_content!
        else
          # Track sha1 conflicts.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/367356
          Gitlab::ErrorTracking.log_exception(
            ArgumentError.new,
            message: 'maven package file sha1 conflict',
            stored_sha1: package_file.file_sha1,
            received_sha256: uploaded_file.sha256,
            sha256_hexdigest_of_stored_sha1: stored_sha256
          )

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

      def present_carrierwave_file_with_head_support!(package_file, supports_direct_download: true)
        package_file.package.touch_last_downloaded_at
        file = package_file.file

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
        ).execute
      end

      def find_and_present_package_file(package, file_name, format, params)
        project = package&.project
        package_file = nil

        package_file = ::Packages::PackageFileFinder.new(package, file_name).execute if package

        no_package_found = package_file ? false : true

        redirect_registry_request(
          forward_to_registry: no_package_found,
          package_type: :maven,
          target: params[:target],
          path: params[:path],
          file_name: params[:file_name]
        ) do
          not_found!('Package') if no_package_found

          case format
          when 'md5'
            package_file.file_md5
          when 'sha1'
            package_file.file_sha1
          else
            track_package_event('pull_package', :maven, project: project, namespace: project&.namespace) if jar_file?(format)

            present_carrierwave_file_with_head_support!(package_file)
          end
        end
      end
    end

    desc 'Download the maven package file at instance level' do
      detail 'This feature was introduced in GitLab 11.6'
      success code: 200
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 404, message: 'Not Found' }
      ]
      tags %w[maven_packages]
    end
    params do
      requires :path, type: String, desc: 'Package path', documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
      requires :file_name, type: String, desc: 'Package file name', documentation: { example: 'mypkg-1.0-SNAPSHOT.jar' }
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

      not_found!('Package') unless package

      package_file = ::Packages::PackageFileFinder
        .new(package, file_name).execute!

      case format
      when 'md5'
        package_file.file_md5
      when 'sha1'
        package_file.file_sha1
      else
        track_package_event('pull_package', :maven, project: project, namespace: project.namespace) if jar_file?(format)

        present_carrierwave_file_with_head_support!(package_file)
      end
    end

    desc 'Download the maven package file at a group level' do
      detail 'This feature was introduced in GitLab 11.7'
      success [
        { code: 200 },
        { code: 302 }
      ]
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 404, message: 'Not Found' }
      ]
      tags %w[maven_packages]
    end
    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        requires :path, type: String, desc: 'Package path', documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
        requires :file_name, type: String, desc: 'Package file name', documentation: { example: 'mypkg-1.0-SNAPSHOT.jar' }
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      get ':id/-/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        # return a similar failure to group = find_group(params[:id])
        group = find_group(params[:id])

        if Feature.disabled?(:maven_central_request_forwarding, group&.root_ancestor)
          not_found!('Group') unless path_exists?(params[:path])
        end

        not_found!('Group') unless can?(current_user, :read_group, group)

        file_name, format = extract_format(params[:file_name])
        package = fetch_package(file_name: file_name, group: group)

        authorize_read_package!(package.project) if package

        find_and_present_package_file(package, file_name, format, params.merge(target: group))
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
        success [
          { code: 200 },
          { code: 302 }
        ]
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[maven_packages]
      end
      params do
        requires :path, type: String, desc: 'Package path', documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
        requires :file_name, type: String, desc: 'Package file name', documentation: { example: 'mypkg-1.0-SNAPSHOT.jar' }
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      get ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        project = user_project(action: :read_package)

        # return a similar failure to user_project
        unless Feature.enabled?(:maven_central_request_forwarding, project&.root_ancestor)
          not_found!('Project') unless path_exists?(params[:path])
        end

        authorize_read_package!(project)

        file_name, format = extract_format(params[:file_name])

        package = fetch_package(file_name: file_name, project: project)

        find_and_present_package_file(package, file_name, format, params.merge(target: project))
      end

      desc 'Workhorse authorize the maven package file upload' do
        detail 'This feature was introduced in GitLab 11.3'
        success code: 200
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[maven_packages]
      end
      params do
        requires :path, type: String, desc: 'Package path', documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
        requires :file_name, type: String, desc: 'Package file name', regexp: Gitlab::Regex.maven_file_name_regex, documentation: { example: 'mypkg-1.0-SNAPSHOT.pom' }
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
        success code: 200
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' },
          { code: 422, message: 'Unprocessable Entity' }
        ]
        tags %w[maven_packages]
      end
      params do
        requires :path, type: String, desc: 'Package path', documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
        requires :file_name, type: String, desc: 'Package file name', regexp: Gitlab::Regex.maven_file_name_regex, documentation: { example: 'mypkg-1.0-SNAPSHOT.pom' }
        requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)', documentation: { type: 'file' }
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      put ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        unprocessable_entity! if Gitlab::FIPS.enabled? && params[:file].md5
        authorize_upload!
        bad_request!('File is too large') if user_project.actual_limits.exceeded?(:maven_max_file_size, params[:file].size)

        file_name, format = extract_format(params[:file_name])

        ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
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
            file_params = {
              file: params[:file],
              size: params[:file].size,
              file_name: file_name,
              file_sha1: params[:file].sha1,
              file_md5: params[:file].md5
            }

            ::Packages::CreatePackageFileService.new(package, file_params.merge(build: current_authenticated_job)).execute
            track_package_event('push_package', :maven, project: user_project, namespace: user_project.namespace) if jar_file?(format)
          end
        end
      end
    end
  end
end
