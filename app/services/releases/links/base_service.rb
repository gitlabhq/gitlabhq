# frozen_string_literal: true

module Releases
  module Links
    REASON_BAD_REQUEST = :bad_request
    REASON_NOT_FOUND = :not_found
    REASON_FORBIDDEN = :forbidden

    class BaseService
      attr_accessor :release, :current_user, :params

      def initialize(release, current_user = nil, params = {})
        @release = release
        @current_user = current_user
        @params = params.dup
      end

      private

      def allowed_params
        Params.new(params).allowed_params
      end
    end
  end
end
