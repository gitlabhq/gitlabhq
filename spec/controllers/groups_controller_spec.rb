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
end
