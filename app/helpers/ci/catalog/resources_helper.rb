# frozen_string_literal: true

module Ci
  module Catalog
    module ResourcesHelper
      def can_add_catalog_resource?(project)
        can?(current_user, :add_catalog_resource, project)
      end

      def can_view_namespace_catalog?(_project)
        false
      end

      def js_ci_catalog_data(_project)
        {}
      end
    end
  end
end

Ci::Catalog::ResourcesHelper.prepend_mod_with('Ci::Catalog::ResourcesHelper')
