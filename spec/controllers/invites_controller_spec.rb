require 'spec_helper'

describe InvitesController do
  let(:token) { '123456' }
  let(:user) { create(:user) }
  let(:member) { create(:project_member, invite_token: token, invite_email: 'test@abc.com', user: user) }

  before do
    controller.instance_variable_set(:@member, member)
    sign_in(user)
  end

  describe 'GET #accept' do
    it 'accepts user' do
      get :accept, id: token
      member.reload

      expect(response).to have_gitlab_http_status(302)
      expect(member.user).to eq(user)
      expect(flash[:notice]).to include 'You have been granted'
    end
  end

  describe 'GET #decline' do
    it 'declines user' do
      get :decline, id: token
      expect {member.reload}.to raise_error ActiveRecord::RecordNotFound

      expect(response).to have_gitlab_http_status(302)
      expect(flash[:notice]).to include 'You have declined the invitation to join'
    end
  end
end
