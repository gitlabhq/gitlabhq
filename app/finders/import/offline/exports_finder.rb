# frozen_string_literal: true

module Import
  module Offline
    class ExportsFinder
      def initialize(user:, params: {})
        @user = user
        @params = params
      end

      def execute
        exports = filter_by_status(user.import_offline_exports)
        sort(exports)
      end

      private

      attr_reader :user, :params

      def filter_by_status(exports)
        return exports unless ::Import::Offline::Export.all_human_statuses.include?(params[:status])

        exports.with_status(params[:status])
      end

      def sort(exports)
        return exports unless params[:sort]

        exports.order_by_created_at(params[:sort])
      end
    end
  end
end
