# frozen_string_literal: true

class TestSuiteSummaryEntity < TestSuiteEntity
  expose :build_ids, documentation: { type: 'integer', is_array: true, example: [66004] } do |summary|
    summary.build_ids
  end

  expose :suite_error,
    documentation: { type: 'string', example: 'JUnit XML parsing failed: 1:1: FATAL: Document is empty' }
end
