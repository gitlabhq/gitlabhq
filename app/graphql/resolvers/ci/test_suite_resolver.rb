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
        builds = pipeline.latest_builds.id_in(build_ids).presence
        return unless builds

        TestSuiteSerializer
          .new(project: pipeline.project, current_user: @current_user)
          .represent(load_test_suite_data(builds), details: true)
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
