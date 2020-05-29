# frozen_string_literal: true

module Ci
  class BuildReportResult < ApplicationRecord
    extend Gitlab::Ci::Model

    self.primary_key = :build_id

    belongs_to :build, class_name: "Ci::Build", inverse_of: :report_results
    belongs_to :project, class_name: "Project", inverse_of: :build_report_results

    validates :build, :project, presence: true
    validates :data, json_schema: { filename: "build_report_result_data" }
  end
end
