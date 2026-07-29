# frozen_string_literal: true

module Resolvers
  module Ci
    class TestSuiteResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type ::Types::Ci::TestSuiteType, null: true
      authorize :read_build
      authorizes_object!

      alias_method :pipeline, :object

      argument :build_ids, [GraphQL::Types::ID],
        required: true,
        description: 'IDs of the builds used to run the test suite.'

      def resolve(build_ids:)
        # rubocop:disable CodeReuse/ActiveRecord -- preload report artifacts and project to avoid N+1 in the per-build access check below
        builds = pipeline
          .latest_builds
          .id_in(build_ids)
          .preload(:project, job_artifacts: :artifact_report)
          .to_a
        # rubocop:enable CodeReuse/ActiveRecord

        # :read_build (authorized above) is not enough to read report content:
        # the JUnit report artifacts carry their own accessibility, so filter to
        # the builds whose report the user may actually read.
        if current_user
          ::Preloaders::UserMaxAccessLevelInProjectsPreloader
            .new(builds.map(&:project).uniq, current_user)
            .execute
        end

        accessible_builds = builds.select { |build| build.test_report_readable_by?(current_user) }
        return if accessible_builds.empty?

        TestSuiteSerializer
          .new(project: pipeline.project, current_user: @current_user)
          .represent(load_test_suite_data(accessible_builds), details: true)
      end

      private

      def load_test_suite_data(builds)
        suite = builds.sum(Gitlab::Ci::Reports::TestSuite.new) do |build|
          test_report = build.collect_test_reports!(Gitlab::Ci::Reports::TestReport.new)
          test_report.get_suite(build.test_suite_name)
        end

        Gitlab::Ci::Reports::TestFailureHistory.new(suite.failed.values, pipeline.project).load!

        suite
      end
    end
  end
end
