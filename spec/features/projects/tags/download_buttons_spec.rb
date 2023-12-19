# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Download buttons in tags page', feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:status) { 'success' }
  let(:tag) { 'v1.0.0' }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: project.commit(tag).sha,
      ref: tag,
      status: status
    )
  end

  let!(:build) do
    create(
      :ci_build, :success, :artifacts,
      pipeline: pipeline,
      status: pipeline.status,
      name: 'build'
    )
  end

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'when checking tags' do
    it_behaves_like 'archive download buttons' do
      let(:path_to_visit) { project_tags_path(project) }
      let(:ref) { tag }
    end
  end
end
