module API
  class MavenPackages < Grape::API
    MAVEN_ENDPOINT_REQUIREMENTS = {
      app_name: API::NO_SLASH_URL_PART_REGEX,
      app_version: API::NO_SLASH_URL_PART_REGEX,
      file_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    content_type :md5, 'text/plain'
    content_type :sha1, 'text/plain'
    content_type :binary, 'application/octet-stream'

    helpers do
      def extract_format(file_name)
        name, _, format = file_name.rpartition('.')

        if %w(md5 sha1).include?(format)
          [name, format]
        else
          [file_name, nil]
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Download the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      params do
        requires :app_group, type: String, desc: 'Package group id'
        requires :app_name, type: String, desc: 'Package artifact id'
        requires :app_version, type: String, desc: 'Package version'
        requires :file_name, type: String, desc: 'Package file name'
      end
      get ':id/packages/maven/*app_group/:app_name/:app_version/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        file_name, format = extract_format(params[:file_name])

        metadata = ::Packages::MavenMetadatum.find_by!(app_group: params[:app_group],
                                                       app_name: params[:app_name],
                                                       app_version: params[:app_version])


        package_file = metadata.package.package_files.find_by!(file: file_name)

        case format
        when 'md5'
          package_file.file_md5
        when 'sha1'
          package_file.file_sha1
        else
          present_carrierwave_file!(package_file.file)
        end
      end

      desc 'Upload the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      put ':id/packages/maven/*app_group/:app_name/:app_version/:file_name', requirements: MAVEN_ENDPOINT_REQUIREMENTS do
        # TODO: Implement me
      end
    end
  end
end
