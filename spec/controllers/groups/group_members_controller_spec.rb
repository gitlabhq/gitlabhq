require 'spec_helper'

describe Groups::GroupMembersController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  context "when public visibility level is restricted" do
    before do
      group.add_owner(user)
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'does not show group members' do
      get :index, group_id: group.path
      expect(response.status).to eq(404)
    end
  end
end
