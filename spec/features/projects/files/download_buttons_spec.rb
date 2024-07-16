# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Download buttons in files tree', feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }

  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit.sha, ref: project.default_branch, status: 'success')
  end

  let!(:build) do
    create(:ci_build, :success, :artifacts, pipeline: pipeline, status: pipeline.status, name: 'build')
  end

  before do
    sign_in(user)
    project.add_developer(user)
  end

  it_behaves_like 'archive download buttons' do
    let(:path_to_visit) { project_tree_path(project, project.default_branch) }
  end
end
