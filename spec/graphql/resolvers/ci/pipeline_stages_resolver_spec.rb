# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::PipelineStagesResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  def resolve_stages(pipeline)
    resolve(described_class, obj: pipeline, ctx: { current_user: current_user })
  end

  describe '#unconditional_includes' do
    it 'includes :pipeline' do
      resolver = resolver_instance(described_class, ctx: query_context(user: nil))

      expect(resolver.unconditional_includes).to include(:pipeline)
    end
  end

  describe 'N+1 prevention' do
    it 'does not issue additional queries per stage when accessing detailed_status' do
      pipeline_1 = create(:ci_pipeline, project: project)
      create(:ci_stage, pipeline: pipeline_1, name: 'build')

      control = ActiveRecord::QueryRecorder.new do
        resolve_stages(pipeline_1).nodes.each { |s| s.detailed_status(current_user) }
      end

      pipeline_2 = create(:ci_pipeline, project: project)
      create(:ci_stage, pipeline: pipeline_2, name: 'build')
      create(:ci_stage, pipeline: pipeline_2, name: 'test')

      expect do
        resolve_stages(pipeline_2).nodes.each { |s| s.detailed_status(current_user) }
      end.not_to exceed_query_limit(control)
    end
  end
end
