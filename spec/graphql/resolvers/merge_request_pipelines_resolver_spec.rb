require 'spec_helper'

describe Resolvers::MergeRequestPipelinesResolver do
  include GraphqlHelpers

  set(:merge_request) { create(:merge_request) }
  set(:pipeline) do
    create(
      :ci_pipeline,
      project: merge_request.source_project,
      ref: merge_request.source_branch,
      sha: merge_request.diff_head_sha
    )
  end
  set(:other_project_pipeline) { create(:ci_pipeline, project: merge_request.source_project) }
  set(:other_pipeline) { create(:ci_pipeline) }
  let(:current_user) { create(:user) }

  before do
    merge_request.project.add_developer(current_user)
  end

  def resolve_pipelines
    resolve(described_class, obj: merge_request, ctx: { current_user: current_user })
  end

  it 'resolves only MRs for the passed merge request' do
    expect(resolve_pipelines).to contain_exactly(pipeline)
  end
end
