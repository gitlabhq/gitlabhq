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
    helpers ::API::Helpers::Packages::Maven
    helpers ::API::Helpers::Packages::Maven::BasicAuthHelpers

    helpers do
      def path_exists?(path)
        return false if path.blank?

        Packages::Maven::Metadatum.with_path(path)
                                  .exists?
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

            download_package_file!(package_file)
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
      use :path_and_file_name
    end
    route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true, basic_auth_personal_access_token: true
    route_setting :authorization, job_token_policies: :read_packages
    get 'packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
      # return a similar failure to authorize_read_package!(project)

      forbidden! unless path_exists?(params[:path])

      file_name, format = extract_format(params[:file_name])

      # To avoid name collision we require project path and project package be the same.
      # For packages that have different name from the project we should use
      # the endpoint that includes project id
      project = find_project_by_path(params[:path])

      authorize_read_package!(project)
      authorize_job_token_policies!(project)

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

        download_package_file!(package_file)
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
        use :path_and_file_name
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true, basic_auth_personal_access_token: true
      route_setting :authorization, job_token_policies: :read_packages
      get ':id/-/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        # return a similar failure to group = find_group(params[:id])
        group = find_authorized_group!(action: :read_package_within_public_registries)

        if Feature.disabled?(:maven_central_request_forwarding, group&.root_ancestor)
          not_found!('Group') unless path_exists?(params[:path])
        end

        file_name, format = extract_format(params[:file_name])
        package = fetch_package(file_name: file_name, group: group)

        if package
          authorize_read_package!(package.project)
          authorize_job_token_policies!(package.project)
        end

        find_and_present_package_file(package, file_name, format, params.merge(target: group))
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download the maven package file at a project level' do
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
        use :path_and_file_name
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true, basic_auth_personal_access_token: true
      route_setting :authorization, job_token_policies: :read_packages
      get ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        project = authorized_user_project(action: :read_package)

        # return a similar failure to user_project
        unless Feature.enabled?(:maven_central_request_forwarding, project&.root_ancestor)
          not_found!('Project') unless path_exists?(params[:path])
        end

        authorize_read_package!(project)
        authorize_job_token_policies!(project)

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
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true, basic_auth_personal_access_token: true
      route_setting :authorization, job_token_policies: :admin_packages
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
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true, basic_auth_personal_access_token: true
      route_setting :authorization, job_token_policies: :admin_packages
      put ':id/packages/maven/*path/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        unprocessable_entity! if Gitlab::FIPS.enabled? && params[:file].md5
        authorize_upload!
        bad_request!('File is too large') if user_project.actual_limits.exceeded?(:maven_max_file_size, params[:file].size)

        # In FIPS mode, we've already told Workhorse not to generate a
        # MD5 checksum via UploadHashFunctions, and the FIPS check above
        # ensures that Workhorse obeys that. However, Gradle will attempt to issue a PUT request
        # with the MD5 checksum, and the publish step will fail if this endpoint returns a
        # 422 (https://github.com/gradle/gradle/blob/v8.5.0/platforms/software/maven/src/main/java/org/gradle/api/publish/maven/internal/publisher/AbstractMavenPublisher.java#L240),
        # so we need to skip the second FIPS check here.
        file_name, format = extract_format(params[:file_name], skip_fips_check: true)

        lb = ::ApplicationRecord.load_balancer
        ::Gitlab::Database::LoadBalancing::SessionMap.current(lb).use_primary do
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
