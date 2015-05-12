require 'spec_helper'

describe Groups::AvatarsController do
  let(:user)  { create(:user) }
  let(:group) { create(:group, owner: user, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }

  before do
    sign_in(user)
  end

  it 'destroy should remove avatar from DB' do
    delete :destroy, group_id: group.path
    @group = assigns(:group)
    expect(@group.avatar.present?).to be_falsey
    expect(@group).to be_valid
  end
end
