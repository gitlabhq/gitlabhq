# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::AuthorizedApplicationsController do
  let(:user) { create(:user) }
  let(:guest) { create(:user) }
  let(:application) { create(:oauth_application, owner: guest) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it 'responds with 404' do
      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let(:application) { create(:oauth_application) }
    let!(:grant) { create(:oauth_access_grant, resource_owner_id: user.id, application: application) }
    let!(:access_token) { create(:oauth_access_token, resource_owner: user, application: application) }

    it 'revokes both access grants and tokens when id is passed' do
      expect(grant).not_to be_revoked
      expect(access_token).not_to be_revoked

      delete :destroy, params: { id: application.id }

      expect(grant.reload).to be_revoked
      expect(access_token.reload).to be_revoked
    end

    it 'revokes a specific token when token_id is passed' do
      expect(grant).not_to be_revoked
      expect(access_token).not_to be_revoked

      # id is required for this path, but is not used by the
      # controller
      delete :destroy, params: { id: 9999999, token_id: access_token.id }

      expect(grant.reload).not_to be_revoked
      expect(access_token.reload).to be_revoked
    end
  end

  it 'includes Two-factor enforcement concern' do
    expect(described_class.included_modules.include?(EnforcesTwoFactorAuthentication)).to eq(true)
  end
end
