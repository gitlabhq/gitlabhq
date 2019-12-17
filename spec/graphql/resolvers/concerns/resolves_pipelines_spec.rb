# frozen_string_literal: true

require 'spec_helper'

describe ResolvesPipelines do
  include GraphqlHelpers

  subject(:resolver) do
    Class.new(Resolvers::BaseResolver) do
      include ResolvesPipelines

      def resolve(**args)
        resolve_pipelines(object, args)
      end
    end
  end

  let(:current_user) { create(:user) }

  set(:project) { create(:project, :private) }
  set(:pipeline) { create(:ci_pipeline, project: project) }
  set(:failed_pipeline) { create(:ci_pipeline, :failed, project: project) }
  set(:ref_pipeline) { create(:ci_pipeline, project: project, ref: 'awesome-feature') }
  set(:sha_pipeline) { create(:ci_pipeline, project: project, sha: 'deadbeef') }

  before do
    project.add_developer(current_user)
  end

  it { is_expected.to have_graphql_arguments(:status, :ref, :sha) }

  it 'finds all pipelines' do
    expect(resolve_pipelines).to contain_exactly(pipeline, failed_pipeline, ref_pipeline, sha_pipeline)
  end

  it 'allows filtering by status' do
    expect(resolve_pipelines(status: 'failed')).to contain_exactly(failed_pipeline)
  end

  it 'allows filtering by ref' do
    expect(resolve_pipelines(ref: 'awesome-feature')).to contain_exactly(ref_pipeline)
  end

  it 'allows filtering by sha' do
    expect(resolve_pipelines(sha: 'deadbeef')).to contain_exactly(sha_pipeline)
  end

  it 'does not return any pipelines if the user does not have access' do
    expect(resolve_pipelines({}, {})).to be_empty
  end

  it 'increases field complexity based on arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, resolver_class: resolver, null: false, max_page_size: 1)

    expect(field.to_graphql.complexity.call({}, {}, 1)).to eq 2
    expect(field.to_graphql.complexity.call({}, { sha: 'foo' }, 1)).to eq 4
    expect(field.to_graphql.complexity.call({}, { sha: 'ref' }, 1)).to eq 4
  end

  def resolve_pipelines(args = {}, context = { current_user: current_user })
    resolve(resolver, obj: project, args: args, ctx: context)
  end
end
