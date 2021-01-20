# frozen_string_literal: true

module Ci
  class TestFailureHistoryService
    class Async
      attr_reader :service

      def initialize(service)
        @service = service
      end

      def perform_if_needed
        TestFailureHistoryWorker.perform_async(service.pipeline.id) if service.should_track_failures?
      end
    end

    MAX_TRACKABLE_FAILURES = 200

    attr_reader :pipeline
    delegate :project, to: :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      return unless should_track_failures?

      track_failures
    end

    def should_track_failures?
      return false unless project.default_branch_or_master == pipeline.ref

      # We fetch for up to MAX_TRACKABLE_FAILURES + 1 builds. So if ever we get
      # 201 total number of builds with the assumption that each job has at least
      # 1 failed test case, then we have at least 201 failed test cases which exceeds
      # the MAX_TRACKABLE_FAILURES of 200. If this is the case, let's early exit so we
      # don't have to parse each JUnit report of each of the 201 builds.
      failed_builds.length <= MAX_TRACKABLE_FAILURES
    end

    def async
      Async.new(self)
    end

    private

    def failed_builds
      @failed_builds ||= pipeline.builds_with_failed_tests(limit: MAX_TRACKABLE_FAILURES + 1)
    end

    def track_failures
      failed_test_cases = gather_failed_test_cases(failed_builds)

      return if failed_test_cases.size > MAX_TRACKABLE_FAILURES

      failed_test_cases.keys.each_slice(100) do |key_hashes|
        Ci::TestCase.transaction do
          ci_test_cases = Ci::TestCase.find_or_create_by_batch(project, key_hashes)
          failures = test_case_failures(ci_test_cases, failed_test_cases)

          Ci::TestCaseFailure.insert_all(failures)
        end
      end
    end

    def gather_failed_test_cases(failed_builds)
      failed_builds.each_with_object({}) do |build, failed_test_cases|
        test_suite = generate_test_suite!(build)
        test_suite.failed.keys.each do |key|
          failed_test_cases[key] = build
        end
      end
    end

    def generate_test_suite!(build)
      # Returns an instance of Gitlab::Ci::Reports::TestSuite
      build.collect_test_reports!(Gitlab::Ci::Reports::TestReports.new)
    end

    def test_case_failures(ci_test_cases, failed_test_cases)
      ci_test_cases.map do |test_case|
        build = failed_test_cases[test_case.key_hash]

        {
          test_case_id: test_case.id,
          build_id: build.id,
          failed_at: build.finished_at
        }
      end
    end
  end
end
