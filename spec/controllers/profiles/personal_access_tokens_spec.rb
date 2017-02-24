require 'spec_helper'

describe Profiles::PersonalAccessTokensController do
  let(:user) { create(:user) }

  describe '#create' do
    def created_token
      PersonalAccessToken.order(:created_at).last
    end

    before { sign_in(user) }

    it "allows creation of a token" do
      name = FFaker::Product.brand

      post :create, personal_access_token: { name: name }

      expect(created_token).not_to be_nil
      expect(created_token.name).to eq(name)
      expect(created_token.expires_at).to be_nil
      expect(PersonalAccessToken.active).to include(created_token)
    end

    it "allows creation of a token with an expiry date" do
      expires_at = 5.days.from_now

      post :create, personal_access_token: { name: FFaker::Product.brand, expires_at: expires_at }

      expect(created_token).not_to be_nil
      expect(created_token.expires_at.to_i).to eq(expires_at.to_i)
    end

    context "scopes" do
      it "allows creation of a token with scopes" do
        post :create, personal_access_token: { name: FFaker::Product.brand, scopes: %w(api read_user) }

        expect(created_token).not_to be_nil
        expect(created_token.scopes).to eq(%w(api read_user))
      end

      it "allows creation of a token with no scopes" do
        post :create, personal_access_token: { name: FFaker::Product.brand, scopes: [] }

        expect(created_token).not_to be_nil
        expect(created_token.scopes).to eq([])
      end
    end
  end
end
