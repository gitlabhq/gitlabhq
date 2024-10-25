# frozen_string_literal: true

module Admin
  module AbuseReports
    class UpdateService < BaseService
      attr_reader :abuse_report, :params, :current_user

      def initialize(abuse_report, current_user, params)
        @abuse_report = abuse_report
        @current_user = current_user
        @params = params
      end

      def execute
        return ServiceResponse.error(message: 'Admin is required') unless current_user&.can_admin_all_resources?

        abuse_report.label_ids = label_ids

        ServiceResponse.success
      end

      private

      def label_ids
        params[:label_ids].filter_map do |id|
          GitlabSchema.parse_gid(id, expected_type: ::AntiAbuse::Reports::Label).model_id
        rescue Gitlab::Graphql::Errors::ArgumentError
        end
      end
    end
  end
end
