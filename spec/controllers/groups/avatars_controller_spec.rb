require 'spec_helper'

describe Groups::AvatarsController do
  let(:user)  { create(:user) }
  let(:group) { create(:group, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  it 'removes avatar from DB calling destroy' do
    delete :destroy, group_id: group.path
    @group = assigns(:group)
    expect(@group.avatar.present?).to be_falsey
    expect(@group).to be_valid
  end
end
