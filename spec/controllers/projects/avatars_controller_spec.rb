require 'spec_helper'

describe Projects::AvatarsController do
  let(:project) { create(:project, :repository, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)
    controller.instance_variable_set(:@project, project)
  end

  it 'GET #show' do
    get :show, namespace_id: project.namespace.id, project_id: project.id

    expect(response).to have_gitlab_http_status(404)
  end

  it 'removes avatar from DB by calling destroy' do
    delete :destroy, namespace_id: project.namespace.id, project_id: project.id
    expect(project.avatar.present?).to be_falsey
    expect(project).to be_valid
  end
end
