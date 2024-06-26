# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::ProjectPipelinesResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:other_pipeline) { create(:ci_pipeline) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:user) { create(:user) }

  context 'when the user has access' do
    let(:current_user) { developer }

    it 'resolves only MRs for the passed merge request' do
      expect(resolve_pipelines).to contain_exactly(pipeline)
    end
  end

  context 'when the user does not have access' do
    let(:current_user) { user }

    it 'does not return pipeline data' do
      expect(resolve_pipelines).to be_empty
    end
  end

  def resolve_pipelines
    resolve(described_class, obj: project, ctx: { current_user: current_user })
  end
end
