require 'spec_helper'

describe Groups::Settings::CiCdController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET #show' do
    it 'renders show with 200 status code' do
      get :show, group_id: group

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end
  end

  describe 'PUT #reset_registration_token' do
    subject { put :reset_registration_token, group_id: group }

    it 'resets runner registration token' do
      expect { subject }.to change { group.reload.runners_token }
    end

    it 'redirects the user to admin runners page' do
      subject

      expect(response).to redirect_to(group_settings_ci_cd_path)
    end
  end
end
