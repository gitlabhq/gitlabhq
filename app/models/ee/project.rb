module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Project` model
  module Project
    extend ActiveSupport::Concern

    included do
      def geo_primary_web_url
        File.join(::Gitlab::Geo.primary_node.url, ::Gitlab::Routing.url_helpers.namespace_project_path(self.namespace, self))
      end

      def geo_primary_http_url_to_repo
        "#{geo_primary_web_url}.git"
      end
    end
  end
end
