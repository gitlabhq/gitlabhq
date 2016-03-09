require 'rails_helper'

describe GroupsController do
  describe 'GET index' do
    context 'as a user' do
      it 'redirects to Groups Dashboard' do
        sign_in(create(:user))

        get :index

        expect(response).to redirect_to(dashboard_groups_path)
      end
    end

    context 'as a guest' do
      it 'redirects to Explore Groups' do
        get :index

        expect(response).to redirect_to(explore_groups_path)
      end
    end
  end

  describe 'GET show' do
    let(:group) { create(:group, visibility_level: 20) }

    it 'checks if group can be read' do
      expect(controller).to receive(:authorize_read_group!)
      get :show, id: group.path
    end
  end

  describe 'POST create' do
    before { sign_in(create(:user)) }

    it 'checks if group can be created' do
      expect(controller).to receive(:authorize_create_group!)
      post :create, { group: { name: "any params" } }
    end
  end

  describe 'DELETE destroy' do
    before { sign_in(create(:user)) }
    let(:group) { create(:group, visibility_level: 20) }

    it 'checks if group can be deleted' do
      expect(controller).to receive(:authorize_admin_group!)
      delete :destroy, id: group.path
    end
  end

  describe 'PUT update' do
    before { sign_in(create(:user)) }
    let(:group) { create(:group, visibility_level: 20) }

    it 'checks if group can be updated' do
      expect_any_instance_of(Groups::UpdateService).to receive(:execute)
      expect(controller).to receive(:authorize_admin_group!)
      put :update, id: group.path, group: { name: 'test' }
    end
  end
end
