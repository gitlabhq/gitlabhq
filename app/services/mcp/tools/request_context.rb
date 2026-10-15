# frozen_string_literal: true

module Mcp
  module Tools
    class RequestContext < Data.define(:current_user, :access_token, :request)
      def initialize(current_user:, access_token: nil, request: nil)
        raise ArgumentError, 'current_user must be a User' unless current_user.is_a?(::User)

        super
      end
    end
  end
end
