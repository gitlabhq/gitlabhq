# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::AccountsController do
  describe 'DELETE unlink' do
    let(:user) { create(:omniauth_user) }

    before do
      sign_in(user)
    end

    it 'renders 404 if someone tries to unlink a non existent provider' do
      delete :unlink, params: { provider: 'github' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    [:saml, :cas3].each do |provider|
      describe "#{provider} provider" do
        let(:user) { create(:omniauth_user, provider: provider.to_s) }

        it "does not allow to unlink connected account" do
          identity = user.identities.last

          delete :unlink, params: { provider: provider.to_s }

          expect(response).to have_gitlab_http_status(:found)
          expect(user.reload.identities).to include(identity)
        end
      end
    end

    [:twitter, :facebook, :google_oauth2, :gitlab, :github, :bitbucket, :crowd, :auth0, :authentiq].each do |provider|
      describe "#{provider} provider" do
        let(:user) { create(:omniauth_user, provider: provider.to_s) }

        it 'allows to unlink connected account' do
          identity = user.identities.last

          delete :unlink, params: { provider: provider.to_s }

          expect(response).to have_gitlab_http_status(:found)
          expect(user.reload.identities).not_to include(identity)
        end
      end
    end
  end
end
