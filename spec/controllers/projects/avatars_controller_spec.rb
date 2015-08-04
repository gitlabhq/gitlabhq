require 'spec_helper'

describe Projects::AvatarsController do
  let(:project) { create(:project, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.team << [user, :developer]
    controller.instance_variable_set(:@project, project)
  end

  it 'destroy should remove avatar from DB' do
    delete :destroy, namespace_id: project.namespace.id, project_id: project.id
    expect(project.avatar.present?).to be_falsey
    expect(project).to be_valid
  end
end
