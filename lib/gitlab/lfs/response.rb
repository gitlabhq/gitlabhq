module Gitlab
  module Lfs
    class Response

      def initialize(project, user, request)
        @origin_project = project
        @project = storage_project(project)
        @user = user
        @env = request.env
        @request = request
      end

      def render_download_object_response(oid)
        render_response_to_download do
          if check_download_sendfile_header?
            render_lfs_sendfile(oid)
          else
            render_not_found
          end
        end
      end

      def render_batch_operation_response
        request_body = JSON.parse(@request.body.read)
        case request_body["operation"]
        when "download"
          render_batch_download(request_body)
        when "upload"
          render_batch_upload(request_body)
        else
          render_not_found
        end
      end

      def render_storage_upload_authorize_response(oid, size)
        render_response_to_push do
          [
            200,
            { "Content-Type" => "application/json; charset=utf-8" },
            [JSON.dump({
              'StoreLFSPath' => "#{Gitlab.config.lfs.storage_path}/tmp/upload",
              'LfsOid' => oid,
              'LfsSize' => size
            })]
          ]
        end
      end

      def render_storage_upload_store_response(oid, size, tmp_file_name)
        render_response_to_push do
          render_lfs_upload_ok(oid, size, tmp_file_name)
        end
      end

      def render_unsupported_deprecated_api
        [
          501,
          { "Content-Type" => "application/json; charset=utf-8" },
          [JSON.dump({
            'message' => 'Server supports batch API only, please update your Git LFS client to version 0.6.0 and up.',
            'documentation_url' => "#{Gitlab.config.gitlab.url}/help",
          })]
        ]
      end

      private

      def render_not_enabled
        [
          501,
          {
            "Content-Type" => "application/json; charset=utf-8",
          },
          [JSON.dump({
            'message' => 'Git LFS is not enabled on this GitLab server, contact your admin.',
            'documentation_url' => "#{Gitlab.config.gitlab.url}/help",
          })]
        ]
      end

      def render_unauthorized
        [
          401,
          {
            'Content-Type' => 'text/plain'
          },
          ['Unauthorized']
        ]
      end

      def render_not_found
        [
          404,
          {
            "Content-Type" => "application/vnd.git-lfs+json"
          },
          [JSON.dump({
            'message' => 'Not found.',
            'documentation_url' => "#{Gitlab.config.gitlab.url}/help",
          })]
        ]
      end

      def render_forbidden
        [
          403,
          {
            "Content-Type" => "application/vnd.git-lfs+json"
          },
          [JSON.dump({
            'message' => 'Access forbidden. Check your access level.',
            'documentation_url' => "#{Gitlab.config.gitlab.url}/help",
          })]
        ]
      end

      def render_lfs_sendfile(oid)
        return render_not_found unless oid.present?

        lfs_object = object_for_download(oid)

        if lfs_object && lfs_object.file.exists?
          [
            200,
            {
              # GitLab-workhorse will forward Content-Type header
              "Content-Type" => "application/octet-stream",
              "X-Sendfile" => lfs_object.file.path
            },
            []
          ]
        else
          render_not_found
        end
      end

      def render_batch_upload(body)
        return render_not_found if body.empty? || body['objects'].nil?

        render_response_to_push do
          response = build_upload_batch_response(body['objects'])
          [
            200,
            {
              "Content-Type" => "application/json; charset=utf-8",
              "Cache-Control" => "private",
            },
            [JSON.dump(response)]
          ]
        end
      end

      def render_batch_download(body)
        return render_not_found if body.empty? || body['objects'].nil?

        render_response_to_download do
          response = build_download_batch_response(body['objects'])
          [
            200,
            {
              "Content-Type" => "application/json; charset=utf-8",
              "Cache-Control" => "private",
            },
            [JSON.dump(response)]
          ]
        end
      end

      def render_lfs_upload_ok(oid, size, tmp_file)
        if store_file(oid, size, tmp_file)
          [
            200,
            {
              'Content-Type' => 'text/plain',
              'Content-Length' => 0
            },
            []
          ]
        else
          [
            422,
            { 'Content-Type' => 'text/plain' },
            ["Unprocessable entity"]
          ]
        end
      end

      def render_response_to_download
        return render_not_enabled unless Gitlab.config.lfs.enabled

        unless @project.public?
          return render_unauthorized unless @user
          return render_forbidden unless user_can_fetch?
        end

        yield
      end

      def render_response_to_push
        return render_not_enabled unless Gitlab.config.lfs.enabled
        return render_unauthorized unless @user
        return render_forbidden unless user_can_push?

        yield
      end

      def check_download_sendfile_header?
        @env['HTTP_X_SENDFILE_TYPE'].to_s == "X-Sendfile"
      end

      def user_can_fetch?
        # Check user access against the project they used to initiate the pull
        @user.can?(:download_code, @origin_project)
      end

      def user_can_push?
        # Check user access against the project they used to initiate the push
        @user.can?(:push_code, @origin_project)
      end

      def storage_project(project)
        if project.forked?
          project.forked_from_project
        else
          project
        end
      end

      def store_file(oid, size, tmp_file)
        tmp_file_path = File.join("#{Gitlab.config.lfs.storage_path}/tmp/upload", tmp_file)

        object = LfsObject.find_or_create_by(oid: oid, size: size)
        if object.file.exists?
          success = true
        else
          success = move_tmp_file_to_storage(object, tmp_file_path)
        end

        if success
          success = link_to_project(object)
        end

        success
      ensure
        # Ensure that the tmp file is removed
        FileUtils.rm_f(tmp_file_path)
      end

      def object_for_download(oid)
        @project.lfs_objects.find_by(oid: oid)
      end

      def move_tmp_file_to_storage(object, path)
        File.open(path) do |f|
          object.file = f
        end

        object.file.store!
        object.save
      end

      def link_to_project(object)
        if object && !object.projects.exists?(@project)
          object.projects << @project
          object.save
        end
      end

      def select_existing_objects(objects)
        objects_oids = objects.map { |o| o['oid'] }
        @project.lfs_objects.where(oid: objects_oids).pluck(:oid).to_set
      end

      def build_upload_batch_response(objects)
        selected_objects = select_existing_objects(objects)

        upload_hypermedia_links(objects, selected_objects)
      end

      def build_download_batch_response(objects)
        selected_objects = select_existing_objects(objects)

        download_hypermedia_links(objects, selected_objects)
      end

      def download_hypermedia_links(all_objects, existing_objects)
        all_objects.each do |object|
          if existing_objects.include?(object['oid'])
            object['actions'] = {
              'download' => {
                'href' => "#{@origin_project.http_url_to_repo}/gitlab-lfs/objects/#{object['oid']}",
                'header' => {
                  'Authorization' => @env['HTTP_AUTHORIZATION']
                }.compact
              }
            }
          else
            object['error'] = {
              'code' => 404,
              'message' => "Object does not exist on the server or you don't have permissions to access it",
            }
          end
        end

        { 'objects' => all_objects }
      end

      def upload_hypermedia_links(all_objects, existing_objects)
        all_objects.each do |object|
          # generate actions only for non-existing objects
          next if existing_objects.include?(object['oid'])

          object['actions'] = {
            'upload' => {
              'href' => "#{@origin_project.http_url_to_repo}/gitlab-lfs/objects/#{object['oid']}/#{object['size']}",
              'header' => {
                'Authorization' => @env['HTTP_AUTHORIZATION']
              }.compact
            }
          }
        end

        { 'objects' => all_objects }
      end
    end
  end
end
