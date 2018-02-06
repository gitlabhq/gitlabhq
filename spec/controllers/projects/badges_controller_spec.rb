require 'spec_helper'

describe Projects::BadgesController do
  let(:project) { pipeline.project }
  let!(:pipeline) { create(:ci_empty_pipeline) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  it 'requests the pipeline badge successfully' do
    get_badge(:pipeline)

    expect(response).to have_gitlab_http_status(:ok)
  end

  it 'requests the coverage badge successfully' do
    get_badge(:coverage)

    expect(response).to have_gitlab_http_status(:ok)
  end

  def get_badge(badge)
    get badge, namespace_id: project.namespace.to_param, project_id: project, ref: pipeline.ref, format: :svg
  end
end
