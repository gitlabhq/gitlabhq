# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::CommitPipelinesResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let(:commit) { create(:commit, project: project) }
  let_it_be(:current_user) { create(:user) }

  let!(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: commit.id,
      ref: 'master',
      status: 'success'
    )
  end
  let!(:pipeline2) do
    create(
      :ci_pipeline,
      project: project,
      sha: commit.id,
      ref: 'master',
      status: 'failed'
    )
  end
  let!(:pipeline3) do
    create(
      :ci_pipeline,
      project: project,
      sha: commit.id,
      ref: 'my_branch',
      status: 'failed'
    )
  end

  before do
    commit.project.add_developer(current_user)
  end

  def resolve_pipelines
    resolve(described_class, obj: commit, ctx: { current_user: current_user }, args: { ref: 'master' })
  end

  it 'resolves pipelines for commit and ref' do
    pipelines = resolve_pipelines

    expect(pipelines).to eq([pipeline2, pipeline])
  end
end
