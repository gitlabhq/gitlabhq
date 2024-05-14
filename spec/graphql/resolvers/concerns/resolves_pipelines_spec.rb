# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResolvesPipelines do
  include GraphqlHelpers

  subject(:resolver) do
    Class.new(Resolvers::BaseResolver) do
      include ResolvesPipelines

      def resolve(**args)
        resolve_pipelines(object, args)
      end
    end
  end

  let_it_be(:current_user) { create(:user) }

  let_it_be(:project) { create(:project, :private, developers: current_user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:failed_pipeline) { create(:ci_pipeline, :failed, project: project) }
  let_it_be(:success_pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:ref_pipeline) { create(:ci_pipeline, project: project, ref: 'awesome-feature') }
  let_it_be(:sha_pipeline) { create(:ci_pipeline, project: project, sha: 'deadbeef') }
  let_it_be(:username_pipeline) { create(:ci_pipeline, project: project, user: current_user) }
  let_it_be(:all_pipelines) do
    [
      pipeline,
      failed_pipeline,
      success_pipeline,
      ref_pipeline,
      sha_pipeline,
      username_pipeline
    ]
  end

  it { is_expected.to have_graphql_arguments(:status, :scope, :ref, :sha, :source, :updated_after, :updated_before, :username) }

  it 'finds all pipelines' do
    expect(resolve_pipelines).to contain_exactly(*all_pipelines)
  end

  it 'allows filtering by status' do
    expect(resolve_pipelines(status: 'failed')).to contain_exactly(failed_pipeline)
  end

  it 'allows filtering by scope' do
    expect(resolve_pipelines(scope: 'finished')).to contain_exactly(failed_pipeline, success_pipeline)
  end

  it 'allows filtering by ref' do
    expect(resolve_pipelines(ref: 'awesome-feature')).to contain_exactly(ref_pipeline)
  end

  it 'allows filtering by sha' do
    expect(resolve_pipelines(sha: 'deadbeef')).to contain_exactly(sha_pipeline)
  end

  context 'filtering by source' do
    let_it_be(:source_pipeline) { create(:ci_pipeline, project: project, source: 'web') }

    it 'does filter by source' do
      expect(resolve_pipelines(source: 'web')).to contain_exactly(source_pipeline)
    end

    it 'returns all the pipelines' do
      expect(resolve_pipelines).to contain_exactly(*all_pipelines, source_pipeline)
    end
  end

  it 'allows filtering by username' do
    expect(resolve_pipelines(username: current_user.username)).to contain_exactly(username_pipeline)
  end

  context 'filtering by updated_at' do
    let_it_be(:old_pipeline) { create(:ci_pipeline, project: project, updated_at: 2.days.ago) }
    let_it_be(:older_pipeline) { create(:ci_pipeline, project: project, updated_at: 5.days.ago) }

    it 'filters by updated_after' do
      expect(resolve_pipelines(updated_after: 3.days.ago)).to contain_exactly(old_pipeline, *all_pipelines)
    end

    it 'filters by updated_before' do
      expect(resolve_pipelines(updated_before: 3.days.ago)).to contain_exactly(older_pipeline)
    end

    it 'filters by both updated_after and updated_before with valid date range' do
      expect(resolve_pipelines(updated_after: 10.days.ago, updated_before: 3.days.ago)).to contain_exactly(older_pipeline)
    end

    it 'filters by both updated_after and updated_before with invalid date range' do
      # updated_after is before updated_before so result set is empty - impossible
      expect(resolve_pipelines(updated_after: 3.days.ago, updated_before: 10.days.ago)).to be_empty
    end
  end

  it 'does not return any pipelines if the user does not have access' do
    expect(resolve_pipelines({}, {})).to be_empty
  end

  it 'increases field complexity based on arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::Types::String, resolver_class: resolver, null: false, max_page_size: 1)

    expect(field.complexity.call({}, {}, 1)).to eq 2
    expect(field.complexity.call({}, { sha: 'foo' }, 1)).to eq 4
    expect(field.complexity.call({}, { sha: 'ref' }, 1)).to eq 4
  end

  def resolve_pipelines(args = {}, context = { current_user: current_user })
    resolve(resolver, obj: project, args: args, ctx: context)
  end
end
