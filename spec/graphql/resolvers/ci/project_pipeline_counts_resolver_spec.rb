# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ProjectPipelineCountsResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:failed_pipeline) { create(:ci_pipeline, :failed, project: project) }
  let_it_be(:success_pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:ref_pipeline) { create(:ci_pipeline, project: project, ref: 'awesome-feature') }
  let_it_be(:sha_pipeline) { create(:ci_pipeline, :running, project: project, sha: 'deadbeef') }
  let_it_be(:on_demand_dast_scan) { create(:ci_pipeline, :success, project: project, source: 'ondemand_dast_scan') }

  let(:current_user) { create(:user, developer_of: project) }

  describe '#resolve' do
    it 'counts pipelines' do
      expect(resolve_pipeline_counts).to have_attributes(
        all: 6,
        finished: 3,
        running: 1,
        pending: 2
      )
    end

    it 'counts by ref' do
      expect(resolve_pipeline_counts(ref: "awesome-feature")).to have_attributes(
        all: 1,
        finished: 0,
        running: 0,
        pending: 1
      )
    end

    it 'counts by sha' do
      expect(resolve_pipeline_counts(sha: "deadbeef")).to have_attributes(
        all: 1,
        finished: 0,
        running: 1,
        pending: 0
      )
    end

    it 'counts by source' do
      expect(resolve_pipeline_counts(source: "ondemand_dast_scan")).to have_attributes(
        all: 1,
        finished: 1,
        running: 0,
        pending: 0
      )
    end
  end

  def resolve_pipeline_counts(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
