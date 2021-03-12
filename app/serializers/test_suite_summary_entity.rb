# frozen_string_literal: true

class TestSuiteSummaryEntity < TestSuiteEntity
  expose :build_ids do |summary|
    summary.build_ids
  end

  expose :suite_error
end
