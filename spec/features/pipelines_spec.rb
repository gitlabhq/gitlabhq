require 'spec_helper'

describe "Pipelines" do
  include GitlabRoutingHelper

  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /:project/pipelines" do

  end

  describe "GET /:project/pipelines/:id" do
    let(:pipeline) { create(:ci_commit, project: project, ref: 'master') }

    before do
      create(:ci_build, :success, commit: pipeline)
    end

    before { visit namespace_project_pipeline_path(project.namespace, project, pipeline) }

    it { expect(page).to()}
  end
end
