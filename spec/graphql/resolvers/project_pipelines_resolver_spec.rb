# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectPipelinesResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:other_pipeline) { create(:ci_pipeline) }

  let(:current_user) { create(:user) }

  before do
    project.add_developer(current_user)
  end

  def resolve_pipelines
    resolve(described_class, obj: project, ctx: { current_user: current_user })
  end

  it 'resolves only MRs for the passed merge request' do
    expect(resolve_pipelines).to contain_exactly(pipeline)
  end
end
