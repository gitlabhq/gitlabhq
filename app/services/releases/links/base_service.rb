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
        @allowed_params ||= params.slice(:name, :url, :link_type).tap do |hash|
          hash[:filepath] = filepath if provided_filepath?
        end
      end

      def provided_filepath?
        params.key?(:direct_asset_path) || params.key?(:filepath)
      end

      def filepath
        params[:direct_asset_path] || params[:filepath]
      end
    end
  end
end
