# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::TestSuiteResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  describe '#resolve' do
    subject(:test_suite) { resolve(described_class, obj: pipeline, args: { build_ids: build_ids }) }

    context 'when pipeline has builds with test reports' do
      let_it_be(:main_pipeline, freeze: false) { create(:ci_pipeline, :with_test_reports_with_three_failures, project: project) }
      let_it_be(:pipeline) { create(:ci_pipeline, :with_test_reports_with_three_failures, project: project, ref: 'new-feature') }

      let(:suite_name) { 'test' }
      let(:build_ids) { pipeline.latest_builds.pluck(:id) }

      before do
        build = main_pipeline.builds.last
        build.update_column(:finished_at, 1.day.ago) # Just to be sure we are included in the report window

        # The JUnit fixture for the given build has 3 failures.
        # This service will create 1 test case failure record for each.
        Ci::TestFailureHistoryService.new(main_pipeline).execute
      end

      it 'renders test suite data' do
        expect(test_suite[:name]).to eq('test')

        # Each test failure in this pipeline has a matching failure in the default branch
        recent_failures = test_suite[:test_cases].map { |tc| tc[:recent_failures] }
        expect(recent_failures).to eq(
          [
            { count: 1, base_branch: 'master' },
            { count: 1, base_branch: 'master' },
            { count: 1, base_branch: 'master' }
          ])
      end
    end

    context 'when pipeline has no builds that matches the given build_ids' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline) }

      let(:suite_name) { 'test' }
      let(:build_ids) { [non_existing_record_id] }

      it 'returns nil' do
        expect(test_suite).to be_nil
      end
    end

    context 'when the build has a maintainer-only test report' do
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
      let_it_be(:maintainer_build) { create(:ci_build, :success, name: 'maintainer-suite', pipeline: pipeline) }
      let_it_be(:public_build) { create(:ci_build, :success, name: 'public-suite', pipeline: pipeline) }
      let_it_be(:guest) { create(:user, guest_of: project) }
      let_it_be(:maintainer) { create(:user, maintainer_of: project) }

      before do
        # Reports-only jobs: JUnit reports with no archive. :read_build alone must
        # not expose maintainer-only content over GraphQL (same leak #show blocks).
        create(:ci_job_artifact, :junit_with_three_failures, :maintainer_only_access, job: maintainer_build)
        create(:ci_job_artifact, :junit_with_three_failures, job: public_build)
      end

      it 'does not expose a maintainer-only report to a user who can read the build but not its artifacts' do
        result = resolve(described_class, obj: pipeline, args: { build_ids: [maintainer_build.id] },
          ctx: { current_user: guest })

        expect(result).to be_nil
      end

      it 'still serves a report the guest may read (confirms the guest holds :read_build)' do
        result = resolve(described_class, obj: pipeline, args: { build_ids: [public_build.id] },
          ctx: { current_user: guest })

        expect(result[:name]).to eq('public-suite')
      end

      it 'exposes the maintainer-only report to a user who can read maintainer artifacts' do
        result = resolve(described_class, obj: pipeline, args: { build_ids: [maintainer_build.id] },
          ctx: { current_user: maintainer })

        expect(result[:name]).to eq('maintainer-suite')
      end
    end
  end
end
