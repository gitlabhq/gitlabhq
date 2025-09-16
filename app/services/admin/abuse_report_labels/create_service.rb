# frozen_string_literal: true

module Admin
  module AbuseReportLabels
    class CreateService < Labels::BaseService
      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params
      end

      def execute
        params[:color] = convert_color_name_to_hex if params[:color].present?
        params[:organization_id] = current_user.organization_id

        ::AntiAbuse::Reports::Label.create(params)
      end
    end
  end
end
