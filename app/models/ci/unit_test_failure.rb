# frozen_string_literal: true

module Ci
  class UnitTestFailure < ApplicationRecord
    extend Gitlab::Ci::Model

    REPORT_WINDOW = 14.days

    validates :unit_test, :build, :failed_at, presence: true

    belongs_to :unit_test, class_name: "Ci::UnitTest", foreign_key: :unit_test_id
    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id

    scope :deletable, -> { where('failed_at < ?', REPORT_WINDOW.ago) }

    def self.recent_failures_count(project:, unit_test_keys:, date_range: REPORT_WINDOW.ago..Time.current)
      joins(:unit_test)
        .where(
          ci_unit_tests: {
            project_id: project.id,
            key_hash: unit_test_keys
          },
          ci_unit_test_failures: {
            failed_at: date_range
          }
        )
        .group(:key_hash)
        .count('ci_unit_test_failures.id')
    end
  end
end
