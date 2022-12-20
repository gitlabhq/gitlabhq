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
      return false unless project.default_branch_or_main == pipeline.ref

      # We fetch for up to MAX_TRACKABLE_FAILURES + 1 builds. So if ever we get
      # 201 total number of builds with the assumption that each job has at least
      # 1 failed unit test, then we have at least 201 failed unit tests which exceeds
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
      failed_unit_tests = gather_failed_unit_tests_from_reports(failed_builds)

      return if failed_unit_tests.size > MAX_TRACKABLE_FAILURES

      failed_unit_tests.each_slice(100) do |batch|
        Ci::UnitTest.transaction do
          unit_test_attrs = ci_unit_test_attrs(batch)
          ci_unit_tests = Ci::UnitTest.find_or_create_by_batch(project, unit_test_attrs)

          failures = ci_unit_test_failure_attrs(ci_unit_tests, failed_unit_tests)
          Ci::UnitTestFailure.insert_all(failures)
        end
      end
    end

    def gather_failed_unit_tests_from_reports(failed_builds)
      failed_builds.each_with_object({}) do |build, failed_unit_tests|
        test_suite = generate_test_suite!(build)
        test_suite.failed.each do |key, unit_test|
          failed_unit_tests[key] = {
            build: build, # This will be used in ci_unit_test_failure_attrs
            unit_test: unit_test # This will be used in ci_unit_test_attrs
          }
        end
      end
    end

    def generate_test_suite!(build)
      test_report = build.collect_test_reports!(Gitlab::Ci::Reports::TestReport.new)
      test_report.get_suite(build.test_suite_name)
    end

    def ci_unit_test_attrs(batch)
      batch.map do |item|
        unit_test = item.last[:unit_test]

        {
          key_hash: unit_test.key,
          name: unit_test.name,
          suite_name: unit_test.suite_name
        }
      end
    end

    def ci_unit_test_failure_attrs(ci_unit_tests, failed_unit_tests)
      ci_unit_tests.map do |ci_unit_test|
        build = failed_unit_tests[ci_unit_test.key_hash][:build]

        {
          unit_test_id: ci_unit_test.id,
          build_id: build.id,
          failed_at: build.finished_at,
          partition_id: build.partition_id
        }
      end
    end
  end
end
