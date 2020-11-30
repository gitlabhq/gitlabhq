# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPipelineResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, iid: '1234') }
  let_it_be(:other_pipeline) { create(:ci_pipeline) }
  let(:current_user) { create(:user) }

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::PipelineType)
  end

  def resolve_pipeline(project, args)
    resolve(described_class, obj: project, args: args, ctx: { current_user: current_user })
  end

  before do
    project.add_developer(current_user)
  end

  it 'resolves pipeline for the passed iid' do
    result = batch_sync do
      resolve_pipeline(project, { iid: '1234' })
    end

    expect(result).to eq(pipeline)
  end

  it 'keeps the queries under the threshold' do
    create(:ci_pipeline, project: project, iid: '1235')

    control = ActiveRecord::QueryRecorder.new do
      batch_sync { resolve_pipeline(project, { iid: '1234' }) }
    end

    expect do
      batch_sync do
        resolve_pipeline(project, { iid: '1234' })
        resolve_pipeline(project, { iid: '1235' })
      end
    end.not_to exceed_query_limit(control)
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

  context 'when the pipeline is a dangling pipeline' do
    let(:pipeline) do
      dangling_source = ::Enums::Ci::Pipeline.dangling_sources.each_value.first
      create(:ci_pipeline, source: dangling_source, project: project)
    end

    it 'resolves pipeline for the passed iid' do
      result = batch_sync do
        resolve_pipeline(project, { iid: pipeline.iid.to_s })
      end

      expect(result).to eq(pipeline)
    end
  end
end
