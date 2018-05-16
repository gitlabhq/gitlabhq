module EE
  module InternalRedirect
    extend ::Gitlab::Utils::Override

    override :host_allowed?
    def host_allowed?(uri)
      return true if super

      # Redirect is not only allowed to current host, but also to other Geo
      # nodes. relative_url_root *must* be ignored here as we don't know what
      # is root and what is path
      truncated = uri.dup.tap { |uri| uri.path = '/' }
      ::GeoNode.with_url_prefix(truncated).exists?
    end
  end
end
