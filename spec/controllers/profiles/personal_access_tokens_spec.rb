require 'spec_helper'

describe Profiles::PersonalAccessTokensController do
  let(:user) { create(:user) }
  let(:token_attributes) { attributes_for(:personal_access_token) }

  describe '#create' do
    def created_token
      PersonalAccessToken.order(:created_at).last
    end

    before { sign_in(user) }

    it "allows creation of a token with scopes" do
      scopes = %w[api read_user]

      post :create, personal_access_token: token_attributes.merge(scopes: scopes)

      expect(created_token).not_to be_nil
      expect(created_token.name).to eq(token_attributes[:name])
      expect(created_token.scopes).to eq(scopes)
      expect(PersonalAccessToken.active).to include(created_token)
    end

    it "allows creation of a token with an expiry date" do
      expires_at = 5.days.from_now

      post :create, personal_access_token: token_attributes.merge(expires_at: expires_at)

      expect(created_token).not_to be_nil
      expect(created_token.expires_at.to_i).to eq(expires_at.to_i)
    end
  end
end
