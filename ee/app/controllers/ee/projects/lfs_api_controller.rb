module EE
  module Projects
    module LfsApiController
      extend ::Gitlab::Utils::Override

      override :batch_operation_disallowed?
      def batch_operation_disallowed?
        super_result = super
        return true if super_result && !::Gitlab::Geo.enabled?

        if super_result && ::Gitlab::Geo.enabled?
          return true if !::Gitlab::Geo.primary? && !::Gitlab::Geo.secondary?
          return true if ::Gitlab::Geo.secondary? && !::Gitlab::Geo.primary_node_configured?
        end

        false
      end

      override :lfs_read_only_message
      def lfs_read_only_message
        return super unless ::Gitlab::Geo.secondary_with_primary?

        (_('You cannot write to a read-only secondary GitLab Geo instance.
          Please use %{link_to_primary_node} instead.') %
          { link_to_primary_node: geo_primary_default_url_to_repo(project) }
        ).html_safe
      end
    end
  end
end
