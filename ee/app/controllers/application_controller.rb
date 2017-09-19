module EE
  module Admin
    module ApplicationController
      def readonly_message
        raise NotImplementedError unless defined?(super)

        return super unless Gitlab::Geo.secondary_with_primary?

        link_to_primary_node = view_context.link_to('primary node', Gitlab::Geo.primary_node.url)
        (_('You are on a read-only GitLab instance. If you want to make any changes, you must visit the %{link_to_primary_node}.') % { link_to_primary_node: link_to_primary_node }).html_safe
      end
    end
  end
end
