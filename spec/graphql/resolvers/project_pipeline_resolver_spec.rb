# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::ProjectPipelineResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, iid: '1234') }
  let_it_be(:other_pipeline) { create(:ci_pipeline) }
  let(:current_user) { create(:user) }

  def resolve_pipeline(project, args)
    resolve(described_class, obj: project, args: args, ctx: { current_user: current_user })
  end

  it 'resolves pipeline for the passed iid' do
    result = batch_sync do
      resolve_pipeline(project, { iid: '1234' })
    end

    expect(result).to eq(pipeline)
  end

  it 'does not resolve a pipeline outside the project' do
    result = batch_sync do
      resolve_pipeline(other_pipeline.project, { iid: '1234' })
    end

    expect(result).to be_nil
  end

  it 'errors when no iid is passed' do
    expect { resolve_pipeline(project, {}) }.to raise_error(ArgumentError)
  end
end
