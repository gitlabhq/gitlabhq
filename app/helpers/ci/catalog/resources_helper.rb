# frozen_string_literal: true

module Ci
  module Catalog
    module ResourcesHelper
      def can_add_catalog_resource?(project)
        can?(current_user, :add_catalog_resource, project)
      end
    end
  end
end

Ci::Catalog::ResourcesHelper.prepend_mod_with('Ci::Catalog::ResourcesHelper')
