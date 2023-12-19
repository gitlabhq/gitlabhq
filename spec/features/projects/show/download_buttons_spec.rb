# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > Download buttons', feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:status) { 'success' }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: project.commit.sha,
      ref: project.default_branch,
      status: status
    )
  end

  let!(:build) do
    create(
      :ci_build,
      :success,
      :artifacts,
      pipeline: pipeline,
      status: pipeline.status,
      name: 'build'
    )
  end

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'when checking project main page' do
    it_behaves_like 'archive download buttons'
  end
end
