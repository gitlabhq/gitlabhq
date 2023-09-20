# frozen_string_literal: true

module Admin
  module AbuseReportLabels
    class CreateService < Labels::BaseService
      def initialize(params = {})
        @params = params
      end

      def execute
        params[:color] = convert_color_name_to_hex if params[:color].present?

        ::Admin::AbuseReportLabel.create(params)
      end
    end
  end
end
