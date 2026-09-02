# frozen_string_literal: true

module API
  module Helpers
    module ResourceAccessTokensHelpers
      def find_source(source_type, id)
        case source_type
        when 'project' then find_project!(id)
        when 'group' then find_group!(id)
        else raise ArgumentError, "Unknown source_type: #{source_type}"
        end
      end

      # Takes the resource as well as the id, unlike PersonalAccessTokensHelpers#find_token, so it must
      # be included after that module for this definition to win.
      def find_token(resource, token_id)
        PersonalAccessTokensFinder.new({ user: resource.bots, impersonation: false }).find_by_id(token_id)
      end
    end
  end
end
