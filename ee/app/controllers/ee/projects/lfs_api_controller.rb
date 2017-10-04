module EE
  module Projects
    module LfsApiController
      def lfs_read_only_message
        raise NotImplementedError unless defined?(super)

        return super unless ::Gitlab::Geo.secondary_with_primary?

        (_('You cannot write to a read-only secondary GitLab Geo instance. Please use %{link_to_primary_node} instead.') % { link_to_primary_node: geo_primary_default_url_to_repo(project) }).html_safe
      end
    end
  end
end
