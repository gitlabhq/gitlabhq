# frozen_string_literal: true

class TestReportsComparerEntity < Grape::Entity
  expose :total_status, as: :status

  expose :summary do
    expose :total_count, as: :total
    expose :resolved_count, as: :resolved
    expose :failed_count, as: :failed
    expose :error_count, as: :errored
  end

  expose :suite_comparers, as: :suites, using: TestSuiteComparerEntity
end
