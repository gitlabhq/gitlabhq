module EE
  module Projects
    module GitHttpClientController
      extend ActiveSupport::Concern

      prepended do
        before_action do
          redirect_to(primary_full_url) if redirect?
        end
      end

      private

      class RouteHelper
        attr_reader :controller_name, :action_name

        ALLOWED_CONTROLLER_AND_ACTIONS = {
          'git_http' => %w{git_receive_pack},
          'lfs_locks_api' => %w{create unlock verify}
        }.freeze

        def initialize(controller_name, action_name, service)
          @controller_name = controller_name
          @action_name = action_name
          @service = service
        end

        def match?(c_name, a_name)
          controller_name == c_name && action_name == a_name
        end

        def redirect?
          git_receive_pack? || controller_and_action_match?
        end

        private

        attr_reader :service

        def git_receive_pack?
          service_or_action_name == 'git-receive-pack'
        end

        def controller_and_action_match?
          !!ALLOWED_CONTROLLER_AND_ACTIONS[controller_name]&.include?(action_name)
        end

        def service_or_action_name
          action_name == 'info_refs' ? service : action_name.dasherize
        end
      end

      class GitLFSHelper
        MINIMUM_GIT_LFS_VERSION = '2.4.2'.freeze

        def initialize(route_helper, operation, current_version)
          @route_helper = route_helper
          @operation = operation
          @current_version = current_version
        end

        def incorrect_version_response
          {
            json: { message: incorrect_version_message },
            content_type: ::LfsRequest::CONTENT_TYPE,
            status: 403
          }
        end

        def redirect?
          return false unless route_helper.match?('lfs_api', 'batch')
          return true if upload?

          false
        end

        def version_ok?
          return false unless current_version

          ::Gitlab::VersionInfo.parse(current_version) >= wanted_version
        end

        private

        attr_reader :route_helper, :operation, :current_version

        def incorrect_version_message
          translation = _("You need git-lfs version %{min_git_lfs_version} (or greater) to continue. Please visit https://git-lfs.github.com")
          translation % { min_git_lfs_version: MINIMUM_GIT_LFS_VERSION }
        end

        def upload?
          operation == 'upload'
        end

        def wanted_version
          ::Gitlab::VersionInfo.parse(MINIMUM_GIT_LFS_VERSION)
        end
      end

      def route_helper
        @route_helper ||= RouteHelper.new(controller_name, action_name, params[:service])
      end

      def git_lfs_helper
        # params[:operation] explained: https://github.com/git-lfs/git-lfs/blob/master/docs/api/batch.md#requests
        @git_lfs_helper ||= GitLFSHelper.new(route_helper, params[:operation], request.headers['User-Agent'])
      end

      def request_fullpath_for_primary
        relative_url_root = ::Gitlab.config.gitlab.relative_url_root.chomp('/')
        request.fullpath.sub(relative_url_root, '')
      end

      def primary_full_url
        File.join(::Gitlab::Geo.primary_node.url, request_fullpath_for_primary)
      end

      def redirect?
        return false unless ::Gitlab::Geo.secondary_with_primary?
        return true if route_helper.redirect?

        if git_lfs_helper.redirect?
          return true if git_lfs_helper.version_ok?

          # git-lfs 2.4.2 is really only required for requests that involve
          # redirection, so we only render if it's an LFS upload operation
          #
          render(git_lfs_helper.incorrect_version_response)
          return false
        end

        false
      end
    end
  end
end
