# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InvitesController do
  let(:token) { '123456' }
  let_it_be(:user) { create(:user) }
  let(:member) { create(:project_member, :invited, invite_token: token, invite_email: user.email) }
  let(:project_members) { member.source.users }

  before do
    controller.instance_variable_set(:@member, member)
    sign_in(user)
  end

  describe 'GET #show' do
    it 'accepts user if invite email matches signed in user' do
      expect do
        get :show, params: { id: token }
      end.to change { project_members.include?(user) }.from(false).to(true)

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include 'You have been granted'
    end

    it 'forces re-confirmation if email does not match signed in user' do
      member.invite_email = 'bogus@email.com'

      expect do
        get :show, params: { id: token }
      end.not_to change { project_members.include?(user) }

      expect(response).to have_gitlab_http_status(:ok)
      expect(flash[:notice]).to be_nil
    end
  end

  describe 'POST #accept' do
    it 'accepts user' do
      expect do
        post :accept, params: { id: token }
      end.to change { project_members.include?(user) }.from(false).to(true)

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include 'You have been granted'
    end
  end

  describe 'GET #decline' do
    it 'declines user' do
      get :decline, params: { id: token }

      expect { member.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include 'You have declined the invitation to join'
    end
  end
end
