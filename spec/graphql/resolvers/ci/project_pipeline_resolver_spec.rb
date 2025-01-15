# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ProjectPipelineResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:project_pipeline_1) { create(:ci_pipeline, project: project, sha: project.commit.sha) }
  let_it_be(:project_pipeline_2) { create(:ci_pipeline, project: project, sha: 'sha') }
  let_it_be(:project_pipeline_3) { create(:ci_pipeline, project: project, sha: 'sha2') }
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
      .with(project, current_user, ids: [project_pipeline_1.id.to_s])
      .and_call_original

    result = batch_sync do
      resolve_pipeline(project, { id: project_pipeline_1.to_global_id })
    end

    expect(result).to eq(project_pipeline_1)
  end

  it 'resolves pipeline for the passed iid' do
    expect(Ci::PipelinesFinder)
      .to receive(:new)
      .with(project, current_user, iids: [project_pipeline_1.iid.to_s])
      .and_call_original

    result = batch_sync do
      resolve_pipeline(project, { iid: project_pipeline_1.iid.to_s })
    end

    expect(result).to eq(project_pipeline_1)
  end

  it 'resolves pipeline for the passed sha' do
    expect(Ci::PipelinesFinder)
      .to receive(:new)
      .with(project, current_user, sha: ['sha'])
      .and_call_original

    result = batch_sync do
      resolve_pipeline(project, { sha: 'sha' })
    end

    expect(result).to eq(project_pipeline_2)
  end

  it 'keeps the queries under the threshold for id' do
    control = ActiveRecord::QueryRecorder.new do
      batch_sync { resolve_pipeline(project, { id: project_pipeline_1.to_global_id }) }
    end

    expect do
      batch_sync do
        resolve_pipeline(project, { id: project_pipeline_1.to_global_id })
        resolve_pipeline(project, { id: project_pipeline_2.to_global_id })
      end
    end.not_to exceed_query_limit(control)
  end

  it 'keeps the queries under the threshold for iid' do
    control = ActiveRecord::QueryRecorder.new do
      batch_sync { resolve_pipeline(project, { iid: project_pipeline_1.iid.to_s }) }
    end

    expect do
      batch_sync do
        resolve_pipeline(project, { iid: project_pipeline_1.iid.to_s })
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
      resolve_pipeline(other_pipeline.project, { iid: project_pipeline_1.iid.to_s })
    end

    expect(result).to be_nil
  end

  it 'does not resolve a pipeline outside the project' do
    result = batch_sync do
      resolve_pipeline(other_pipeline.project, { id: project_pipeline_1.to_global_id })
    end

    expect(result).to be_nil
  end

  context 'when no id, iid or sha is passed' do
    it 'returns latest pipeline' do
      result = batch_sync do
        resolve_pipeline(project, {})
      end

      expect(result).to eq(project_pipeline_1)
    end

    it 'does not reduce complexity score' do
      field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String, resolver_class: described_class,
        null: false, max_page_size: 1)

      expect(field.complexity.call({}, {}, 1)).to eq 2
    end
  end

  context 'when id is passed' do
    it 'reduces complexity score' do
      field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String, resolver_class: described_class,
        null: false, max_page_size: 1)

      expect(field.complexity.call({}, { id: project_pipeline_1.to_global_id }, 1)).to eq(-7)
    end
  end

  context 'when iid is passed' do
    it 'reduces complexity score' do
      field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String, resolver_class: described_class,
        null: false, max_page_size: 1)

      expect(field.complexity.call({}, { iid: project_pipeline_1.iid.to_s }, 1)).to eq(-7)
    end
  end

  context 'when sha is passed' do
    it 'reduces complexity score' do
      field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String, resolver_class: described_class,
        null: false, max_page_size: 1)

      expect(field.complexity.call({}, { sha: 'sha' }, 1)).to eq(-7)
    end
  end

  it 'errors when both iid and sha are passed' do
    expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError) do
      resolve_pipeline(project, { iid: project_pipeline_1.iid.to_s, sha: 'sha' })
    end
  end

  it 'errors when both id and iid are passed' do
    expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError) do
      resolve_pipeline(project, { id: project_pipeline_1.to_global_id, iid: project_pipeline_1.iid.to_s })
    end
  end

  it 'errors when id, iid and sha are passed' do
    expect_graphql_error_to_be_created(GraphQL::Schema::Validator::ValidationFailedError) do
      resolve_pipeline(project,
        { id: project_pipeline_1.to_global_id, iid: project_pipeline_1.iid.to_s, sha: '12345234' })
    end
  end

  context 'when the pipeline is a dangling pipeline' do
    let(:pipeline) do
      dangling_source = ::Enums::Ci::Pipeline.dangling_sources.each_value.first
      create(:ci_pipeline, source: dangling_source, project: project)
    end

    it 'resolves pipeline for the passed iid' do
      result = batch_sync do
        resolve_pipeline(project, { iid: project_pipeline_1.iid.to_s })
      end

      expect(result).to eq(project_pipeline_1)
    end
  end
end
