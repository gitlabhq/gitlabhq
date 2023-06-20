# frozen_string_literal: true

module Releases
  module Links
    class Params
      def initialize(params)
        @params = params.with_indifferent_access
      end

      def allowed_params
        @allowed_params ||= params.slice(:name, :url, :link_type).tap do |hash|
          hash[:filepath] = filepath if provided_filepath?
        end
      end

      private

      attr_reader :params

      def provided_filepath?
        params.key?(:direct_asset_path) || params.key?(:filepath)
      end

      def filepath
        params[:direct_asset_path] || params[:filepath]
      end
    end
  end
end
