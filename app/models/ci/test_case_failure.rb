# frozen_string_literal: true

module Ci
  class TestCaseFailure < ApplicationRecord
    extend Gitlab::Ci::Model

    REPORT_WINDOW = 14.days

    validates :test_case, :build, :failed_at, presence: true

    belongs_to :test_case, class_name: "Ci::TestCase", foreign_key: :test_case_id
    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id

    def self.recent_failures_count(project:, test_case_keys:, date_range: REPORT_WINDOW.ago..Time.current)
      joins(:test_case)
        .where(
          ci_test_cases: {
            project_id: project.id,
            key_hash: test_case_keys
          },
          ci_test_case_failures: {
            failed_at: date_range
          }
        )
        .group(:key_hash)
        .count('ci_test_case_failures.id')
    end
  end
end
