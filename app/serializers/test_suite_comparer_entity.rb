class TestSuiteComparerEntity < Grape::Entity
  expose :name
  expose :total_status, as: :status

  expose :summary do
    expose :total_count, as: :total
    expose :resolved_count, as: :resolved
    expose :failed_count, as: :failed
  end

  expose :new_failures, using: TestCaseEntity
  expose :resolved_failures, using: TestCaseEntity
  expose :existing_failures, using: TestCaseEntity
end
