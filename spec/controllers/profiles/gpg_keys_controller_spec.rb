# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::GpgKeysController do
  let(:user) { create(:user, email: GpgHelpers::User1.emails[0]) }

  describe 'POST #create' do
    before do
      sign_in(user)
    end

    it 'creates a new key' do
      expect do
        post :create, params: { gpg_key: build(:gpg_key).attributes }
      end.to change { GpgKey.count }.by(1)
    end
  end

  describe "#get_keys" do
    describe "non existent user" do
      it "does not generally work" do
        get :get_keys, params: { username: 'not-existent' }

        expect(response).not_to be_successful
      end
    end

    describe "user with no keys" do
      it "does generally work" do
        get :get_keys, params: { username: user.username }

        expect(response).to be_successful
      end

      it "renders all keys separated with a new line" do
        get :get_keys, params: { username: user.username }

        expect(response.body).to eq("")
      end

      it "responds with text/plain content type" do
        get :get_keys, params: { username: user.username }

        expect(response.content_type).to eq("text/plain")
      end
    end

    describe "user with keys" do
      let!(:gpg_key) { create(:gpg_key, user: user) }
      let!(:another_gpg_key) { create(:another_gpg_key, user: user) }

      describe "while signed in" do
        before do
          sign_in(user)
        end

        it "does generally work" do
          get :get_keys, params: { username: user.username }

          expect(response).to be_successful
        end

        it "renders all verified keys separated with a new line" do
          get :get_keys, params: { username: user.username }

          expect(response.body).not_to eq('')
          expect(response.body).to eq(user.gpg_keys.select(&:verified?).map(&:key).join("\n"))

          expect(response.body).to include(gpg_key.key)
          expect(response.body).to include(another_gpg_key.key)
        end

        it "responds with text/plain content type" do
          get :get_keys, params: { username: user.username }

          expect(response.content_type).to eq("text/plain")
        end
      end

      describe 'when logged out' do
        before do
          sign_out(user)
        end

        it "still does generally work" do
          get :get_keys, params: { username: user.username }

          expect(response).to be_successful
        end

        it "renders all verified keys separated with a new line" do
          get :get_keys, params: { username: user.username }

          expect(response.body).not_to eq('')
          expect(response.body).to eq(user.gpg_keys.map(&:key).join("\n"))

          expect(response.body).to include(gpg_key.key)
          expect(response.body).to include(another_gpg_key.key)
        end

        it "responds with text/plain content type" do
          get :get_keys, params: { username: user.username }

          expect(response.content_type).to eq("text/plain")
        end
      end

      describe 'when revoked' do
        before do
          sign_in(user)
          another_gpg_key.revoke
        end

        it "doesn't render revoked keys" do
          get :get_keys, params: { username: user.username }

          expect(response.body).not_to eq('')

          expect(response.body).to include(gpg_key.key)
          expect(response.body).not_to include(another_gpg_key.key)
        end

        it "doesn't render revoked keys for non-authorized users" do
          sign_out(user)
          get :get_keys, params: { username: user.username }

          expect(response.body).not_to eq('')

          expect(response.body).to include(gpg_key.key)
          expect(response.body).not_to include(another_gpg_key.key)
        end
      end
    end
  end
end
