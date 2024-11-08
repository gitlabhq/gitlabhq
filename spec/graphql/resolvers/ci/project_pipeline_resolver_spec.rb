# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ProjectPipelineResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: 'sha') }
  let_it_be(:other_project_pipeline) { create(:ci_pipeline, project: project, sha: 'sha2') }
  let_it_be(:other_pipeline) { create(:ci_pipeline) }

  let(:current_user) { create(:user, developer_of: project) }

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::PipelineType)
  end

  def resolve_pipeline(project, args)
    resolve(described_class, obj: project, args: args, ctx: { current_user: current_user })
  end

  it 'resolves pipeline for the passed id' do
    expect(Ci::PipelinesFinder)
      .to receive(:new)
      .with(project, current_user, ids: [pipeline.id.to_s])
      .and_call_original

    result = batch_sync do
      resolve_pipeline(project, { id: "gid://gitlab/Ci::Pipeline/#{pipeline.id}" })
    end

    expect(result).to eq(pipeline)
  end

  it 'resolves pipeline for the passed iid' do
    expect(Ci::PipelinesFinder)
      .to receive(:new)
      .with(project, current_user, iids: [pipeline.iid.to_s])
      .and_call_original

    result = batch_sync do
      resolve_pipeline(project, { iid: pipeline.iid.to_s })
    end

    expect(result).to eq(pipeline)
  end

  it 'resolves pipeline for the passed sha' do
    expect(Ci::PipelinesFinder)
      .to receive(:new)
      .with(project, current_user, sha: ['sha'])
      .and_call_original

    result = batch_sync do
      resolve_pipeline(project, { sha: 'sha' })
    end

    expect(result).to eq(pipeline)
  end

  it 'keeps the queries under the threshold for id' do
    control = ActiveRecord::QueryRecorder.new do
      batch_sync { resolve_pipeline(project, { id: "gid://gitlab/Ci::Pipeline/#{pipeline.id}" }) }
    end

    expect do
      batch_sync do
        resolve_pipeline(project, { id: "gid://gitlab/Ci::Pipeline/#{pipeline.id}" })
        resolve_pipeline(project, { id: "gid://gitlab/Ci::Pipeline/#{other_project_pipeline.id}" })
      end
    end.not_to exceed_query_limit(control)
  end

  it 'keeps the queries under the threshold for iid' do
    control = ActiveRecord::QueryRecorder.new do
      batch_sync { resolve_pipeline(project, { iid: pipeline.iid.to_s }) }
    end

    expect do
      batch_sync do
        resolve_pipeline(project, { iid: pipeline.iid.to_s })
        resolve_pipeline(project, { iid: other_pipeline.iid.to_s })
      end
    end.not_to exceed_query_limit(control)
  end

  it 'keeps the queries under the threshold for sha' do
    control = ActiveRecord::QueryRecorder.new do
      batch_sync { resolve_pipeline(project, { sha: 'sha' }) }
    end

    expect do
      batch_sync do
        resolve_pipeline(project, { sha: 'sha' })
        resolve_pipeline(project, { sha: 'sha2' })
      end
    end.not_to exceed_query_limit(control)
  end

  it 'does not resolve a pipeline outside the project' do
    result = batch_sync do
      resolve_pipeline(other_pipeline.project, { iid: pipeline.iid.to_s })
    end

    expect(result).to be_nil
  end

  it 'does not resolve a pipeline outside the project' do
    result = batch_sync do
      resolve_pipeline(other_pipeline.project, { id: "gid://gitlab/Ci::Pipeline/#{pipeline.id}9" })
    end

    expect(result).to be_nil
  end

  it 'errors when no id, iid or sha is passed' do
    expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError) do
      resolve_pipeline(project, {})
    end
  end

  it 'errors when both iid and sha are passed' do
    expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError) do
      resolve_pipeline(project, { iid: pipeline.iid.to_s, sha: 'sha' })
    end
  end

  it 'errors when both id and iid are passed' do
    expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError) do
      resolve_pipeline(project, { id: "gid://gitlab/Ci::Pipeline/#{pipeline.id}", iid: pipeline.iid.to_s })
    end
  end

  it 'errors when id, iid and sha are passed' do
    expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError) do
      resolve_pipeline(project,
        { id: "gid://gitlab/Ci::Pipeline/#{pipeline.id}", iid: pipeline.iid.to_s, sha: '12345234' })
    end
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
