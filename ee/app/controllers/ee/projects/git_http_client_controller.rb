module EE
  module Projects
    module GitHttpClientController
      extend ActiveSupport::Concern

      ALLOWED_CONTROLLER_AND_ACTIONS = {
        'git_http' => %w{git_receive_pack},
        'lfs_api' => %w{batch},
        'lfs_locks_api' => %w{create unlock verify}
      }.freeze

      prepended do
        before_action do
          redirect_to(primary_full_url) if redirect?
        end
      end

      private

      class RouteHelper
        attr_reader :controller_name, :action_name

        def initialize(controller_name, action_name, params, allowed)
          @controller_name = controller_name
          @action_name = action_name
          @params = params
          @allowed = allowed
        end

        def match?(c_name, a_name)
          controller_name == c_name && action_name == a_name
        end

        def allowed_match?
          !!allowed[controller_name]&.include?(action_name)
        end

        def service_or_action_name
          action_name == 'info_refs' ? params[:service] : action_name.dasherize
        end

        private

        attr_reader :params, :allowed
      end

      class GitLFSHelper
        MINIMUM_GIT_LFS_VERSION = '2.4.2'.freeze

        def initialize(current_version)
          @current_version = current_version
        end

        def version_ok?
          return false unless current_version

          ::Gitlab::VersionInfo.parse(current_version) >= wanted_version
        end

        def incorrect_version_opts
          {
            json: { message: incorrect_version_message },
            content_type: ::LfsRequest::CONTENT_TYPE,
            status: 403
          }
        end

        private

        attr_reader :current_version

        def wanted_version
          ::Gitlab::VersionInfo.parse(MINIMUM_GIT_LFS_VERSION)
        end

        def incorrect_version_message
          _("You need git-lfs version %{min_git_lfs_version} (or greater) to
            continue. Please visit https://git-lfs.github.com") %
            { min_git_lfs_version: MINIMUM_GIT_LFS_VERSION }
        end
      end

      def route_helper
        @route_helper ||= RouteHelper.new(controller_name, action_name, params,
                    ALLOWED_CONTROLLER_AND_ACTIONS)
      end

      def git_lfs_helper
        @git_lfs_helper ||= GitLFSHelper.new(current_git_lfs_version)
      end

      def request_fullpath_for_primary
        relative_url_root = ::Gitlab.config.gitlab.relative_url_root.chomp('/')
        request.fullpath.sub(relative_url_root, '')
      end

      def primary_full_url
        File.join(::Gitlab::Geo.primary_node.url, request_fullpath_for_primary)
      end

      def current_git_lfs_version
        request.headers['User-Agent']
      end

      def redirect?
        ::Gitlab::Geo.secondary_with_primary? && match? && !filtered?
      end

      def match?
        route_helper.service_or_action_name == 'git-receive-pack' ||
          route_helper.allowed_match?
      end

      def filtered?
        if route_helper.match?('lfs_api', 'batch') && !git_lfs_helper.version_ok?
          render(git_lfs_helper.incorrect_version_opts)
          return true
        end

        false
      end
    end
  end
end
