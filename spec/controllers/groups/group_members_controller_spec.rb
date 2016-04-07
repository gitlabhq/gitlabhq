require 'spec_helper'

describe Groups::GroupMembersController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  context "index" do
    before do
      group.add_owner(user)
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'renders index with group members' do
      get :index, group_id: group.path

      expect(response.status).to eq(200)
      expect(response).to render_template(:index)
    end
  end
end
