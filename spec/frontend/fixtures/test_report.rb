# frozen_string_literal: true

require "spec_helper"

describe Projects::PipelinesController, "(JavaScript fixtures)", type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: "frontend-fixtures") }
  let(:project) { create(:project, :repository, namespace: namespace, path: "pipelines-project") }
  let(:commit) { create(:commit, project: project) }
  let(:user) { create(:user, developer_projects: [project], email: commit.author_email) }
  let(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project, user: user) }

  render_views

  before do
    sign_in(user)
    stub_feature_flags(junit_pipeline_view: true)
  end

  it "pipelines/test_report.json" do
    get :test_report, params: {
      namespace_id: project.namespace,
      project_id: project,
      id: pipeline.id
    }, format: :json

    expect(response).to be_successful
  end
end
