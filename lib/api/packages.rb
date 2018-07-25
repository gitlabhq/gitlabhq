module API
  class Packages < Grape::API
    content_type :md5, 'text/plain'
    content_type :sha1, 'text/plain'

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Download the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      get ':id/maven/*file_path' do
        checksum = %w(md5 sha1).include?(params[:format])

        file_path, _, file_name = params[:file_path].rpartition('/')
        file_name = file_name + '.' + params[:format] unless checksum

        app_path, _, version = file_path.rpartition('/')
        app_group, _, app_name = app_path.rpartition('/')

        metadata = ::Packages::MavenMetadatum.find_by(app_group: app_group,
                                                    app_name: app_name,
                                                    app_version: version)

        package_file = metadata.package.package_files.find_by(file: file_name)

        if checksum
          case params[:format]
          when 'md5'
            package_file.file_md5
          when 'sha1'
            package_file.file_sha1
          end
        else
          present_carrierwave_file!(package_file.file)
        end
      end

      desc 'Upload the maven package file' do
        detail 'This feature was introduced in GitLab 11.3'
      end
      post ':id/maven/*file_path' do
        # parse file path, create an upload, save record in database
      end
    end
  end
end
