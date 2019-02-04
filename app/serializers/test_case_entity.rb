# frozen_string_literal: true

class TestCaseEntity < Grape::Entity
  expose :status
  expose :name
  expose :execution_time
  expose :system_output
  expose :stack_trace
end
