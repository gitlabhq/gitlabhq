require 'spec_helper'

describe Groups::LabelsController do
  let(:group) { create(:group) }
  let(:user)  { create(:user) }

  before do
    group.add_owner(user)

    sign_in(user)
  end

  describe 'POST #toggle_subscription' do
    it 'allows user to toggle subscription on group labels' do
      label = create(:group_label, group: group)

      post :toggle_subscription, group_id: group.to_param, id: label.to_param

      expect(response).to have_http_status(200)
    end
  end
end
