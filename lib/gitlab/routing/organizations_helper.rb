# frozen_string_literal: true

module Gitlab
  module Routing
    module OrganizationsHelper
      extend ActiveSupport::Concern

      # Check if this is an organization route (/o/org-path/...)
      def organization_scoped_route?(path)
        return false unless path

        path.start_with?('/o/')
      end

      module_function :organization_scoped_route?
    end
  end
end
