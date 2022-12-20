# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerJobsResolver, feature_category: :runner_fleet do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:irrelevant_pipeline) { create(:ci_pipeline, project: project) }

  let!(:build_one) { create(:ci_build, :success, name: 'Build One', runner: runner, pipeline: pipeline) }
  let!(:build_two) { create(:ci_build, :success, name: 'Build Two', runner: runner, pipeline: pipeline) }
  let!(:build_three) { create(:ci_build, :failed, name: 'Build Three', runner: runner, pipeline: pipeline) }
  let!(:irrelevant_build) { create(:ci_build, name: 'Irrelevant Build', pipeline: irrelevant_pipeline) }

  let(:args) { {} }
  let(:runner) { create(:ci_runner, :project, projects: [project]) }

  subject { resolve_jobs(args) }

  describe '#resolve' do
    context 'with authorized user', :enable_admin_mode do
      let(:current_user) { create(:user, :admin) }

      context 'with statuses argument' do
        let(:args) { { statuses: [Types::Ci::JobStatusEnum.coerce_isolated_input('SUCCESS')] } }

        it { is_expected.to contain_exactly(build_one, build_two) }
      end

      context 'without statuses argument' do
        it { is_expected.to contain_exactly(build_one, build_two, build_three) }
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { nil }

      it { is_expected.to be_nil }
    end
  end

  private

  def resolve_jobs(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: runner, args: args, ctx: context)
  end
end
