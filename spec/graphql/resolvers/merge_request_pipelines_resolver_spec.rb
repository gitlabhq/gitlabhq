# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequestPipelinesResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:pipeline) do
    create(
      :ci_pipeline,
      project: merge_request.source_project,
      ref: merge_request.source_branch,
      sha: merge_request.diff_head_sha
    )
  end

  let_it_be(:other_project_pipeline) { create(:ci_pipeline, project: merge_request.source_project, ref: 'other-ref') }
  let_it_be(:other_pipeline) { create(:ci_pipeline) }

  let(:current_user) { create(:user) }

  before do
    merge_request.project.add_developer(current_user)
  end

  def resolve_pipelines
    sync(resolve(described_class, obj: merge_request, ctx: { current_user: current_user }))
  end

  it 'resolves only MRs for the passed merge request' do
    expect(resolve_pipelines).to contain_exactly(pipeline)
  end

  describe 'with archived project' do
    let(:archived_project) { create(:project, :archived) }
    let(:merge_request) { create(:merge_request, source_project: archived_project) }

    it { expect(resolve_pipelines).not_to contain_exactly(pipeline) }
  end

  describe 'ordering' do
    # `mr_pipeline` is created before `branch_pipeline`, so it has a lower id.
    # With a plain `id DESC` it would come last; the resolver opts into
    # `merge_request_event_first`, so it must be surfaced first instead.
    let_it_be(:mr_pipeline) do
      create(:ci_pipeline, :detached_merge_request_pipeline, merge_request: merge_request)
    end

    let_it_be(:branch_pipeline) do
      create(
        :ci_pipeline,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha
      )
    end

    it 'returns merge_request_event pipelines first, ahead of higher-id branch pipelines' do
      pipelines = resolve_pipelines.to_a

      expect(pipelines.first).to eq(mr_pipeline)
      expect(pipelines.index(mr_pipeline)).to be < pipelines.index(branch_pipeline)
    end
  end
end
