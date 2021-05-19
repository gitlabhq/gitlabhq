# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequestPipelinesResolver do
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
end
