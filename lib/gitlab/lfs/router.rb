module Gitlab
  module Lfs
    class Router
      def initialize(project, user, request)
        @project = project
        @user = user
        @env = request.env
        @request = request
      end

      def try_call
        return unless @request && @request.path.present?

        case @request.request_method
        when 'GET'
          get_response
        when 'POST'
          post_response
        when 'PUT'
          put_response
        else
          nil
        end
      end

      private

      def get_response
        path_match = @request.path.match(/\/(info\/lfs|gitlab-lfs)\/objects\/([0-9a-f]{64})$/)
        return nil unless path_match

        oid = path_match[2]
        return nil unless oid

        case path_match[1]
        when "info/lfs"
          lfs.render_unsupported_deprecated_api
        when "gitlab-lfs"
          lfs.render_download_object_response(oid)
        else
          nil
        end
      end

      def post_response
        post_path = @request.path.match(/\/info\/lfs\/objects(\/batch)?$/)
        return nil unless post_path

        # Check for Batch API
        if post_path[0].ends_with?("/info/lfs/objects/batch")
          lfs.render_batch_operation_response
        elsif post_path[0].ends_with?("/info/lfs/objects")
          lfs.render_unsupported_deprecated_api
        else
          nil
        end
      end

      def put_response
        object_match = @request.path.match(/\/gitlab-lfs\/objects\/([0-9a-f]{64})\/([0-9]+)(|\/authorize){1}$/)
        return nil if object_match.nil?

        oid = object_match[1]
        size = object_match[2].try(:to_i)
        return nil if oid.nil? || size.nil?

        # GitLab-workhorse requests
        # 1. Try to authorize the request
        # 2. send a request with a header containing the name of the temporary file
        if object_match[3] && object_match[3] == '/authorize'
          lfs.render_storage_upload_authorize_response(oid, size)
        else
          tmp_file_name = sanitize_tmp_filename(@request.env['HTTP_X_GITLAB_LFS_TMP'])
          return nil unless tmp_file_name

          lfs.render_storage_upload_store_response(oid, size, tmp_file_name)
        end
      end

      def lfs
        return unless @project

        Gitlab::Lfs::Response.new(@project, @user, @request)
      end

      def sanitize_tmp_filename(name)
        if name.present?
          name.gsub!(/^.*(\\|\/)/, '')
          name = name.match(/[0-9a-f]{73}/)
          name[0] if name
        else
          nil
        end
      end
    end
  end
end
