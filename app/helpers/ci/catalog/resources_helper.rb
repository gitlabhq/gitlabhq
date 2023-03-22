# frozen_string_literal: true

module Ci
  module Catalog
    module ResourcesHelper
      def can_view_private_catalog?(_project)
        false
      end

      def js_ci_catalog_data(_project)
        {}
      end
    end
  end
end
