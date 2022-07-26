# frozen_string_literal: true

module QA
  module Resource
    module Integrations
      module Project
        def find_integration(slug)
          fetch_integrations.find do |integration|
            integration[:slug] == slug
          end
        end

        def fetch_integrations
          parse_body api_get_from(api_get_integrations)
        end

        private

        def api_get_integrations
          "#{api_get_path}/integrations"
        end
      end
    end
  end
end
