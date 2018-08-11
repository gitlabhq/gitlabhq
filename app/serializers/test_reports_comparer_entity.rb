# frozen_string_literal: true

class TestReportsComparerEntity < Grape::Entity
  expose :total_status, as: :status

  expose :summary do
    expose :total_count, as: :total
    expose :resolved_count, as: :resolved
    expose :failed_count, as: :failed
  end

  expose :suite_comparers, as: :suites, using: TestSuiteComparerEntity
end
