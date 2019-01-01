require 'spec_helper'

describe Groups::Settings::CiCdController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'renders show with 200 status code' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template(:show)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        get :show, params: { group_id: group }

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'PUT #reset_registration_token' do
    subject { put :reset_registration_token, params: { group_id: group } }

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'resets runner registration token' do
        expect { subject }.to change { group.reload.runners_token }
      end

      it 'redirects the user to admin runners page' do
        subject

        expect(response).to redirect_to(group_settings_ci_cd_path)
      end
    end

    context 'when user is not owner' do
      before do
        group.add_maintainer(user)
      end

      it 'renders a 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
