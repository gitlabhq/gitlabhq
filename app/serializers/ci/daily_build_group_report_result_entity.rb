# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResultEntity < Grape::Entity
    expose :date

    ::Ci::DailyBuildGroupReportResult::PARAM_TYPES.each do |type|
      expose type, if: ->(report_result, options) { options[:param_type] == type } do |report_result, options|
        report_result.data[options[:param_type]]
      end
    end
  end
end
