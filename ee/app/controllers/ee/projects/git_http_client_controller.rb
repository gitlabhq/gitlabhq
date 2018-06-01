module EE
  module Projects
    module GitHttpClientController
      extend ActiveSupport::Concern

      prepended do
        before_action :redirect_push_to_primary, only: [:info_refs]
      end

      private

      def redirect_push_to_primary
        redirect_to(primary_full_url) if redirect_push_to_primary?
      end

      def primary_full_url
        File.join(::Gitlab::Geo.primary_node.url, request_fullpath_for_primary)
      end

      def request_fullpath_for_primary
        relative_url_root = ::Gitlab.config.gitlab.relative_url_root.chomp('/')
        request.fullpath.sub(relative_url_root, '')
      end

      def redirect_push_to_primary?
        git_push_request? && ::Gitlab::Geo.secondary_with_primary?
      end

      def git_push_request?
        git_command == 'git-receive-pack'
      end
    end
  end
end
