# frozen_string_literal: true

module QA
  module Resource
    module Visibility
      def set_visibility(visibility)
        put Runtime::API::Request.new(api_client, api_visibility_path).url, { visibility: visibility }
      end

      class VisibilityLevel
        %i[public internal private].each do |level|
          const_set(level.upcase, level)
        end
      end
    end
  end
end
