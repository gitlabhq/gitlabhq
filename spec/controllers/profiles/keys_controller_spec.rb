# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::KeysController do
  let(:user) { create(:user) }

  describe 'POST #create' do
    before do
      sign_in(user)
    end

    it 'creates a new key' do
      expires_at = 3.days.from_now

      expect do
        post :create, params: { key: build(:key, expires_at: expires_at).attributes }
      end.to change { Key.count }.by(1)

      expect(Key.last.expires_at).to be_like_time(expires_at)
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
      let!(:key) { create(:key, user: user) }
      let!(:another_key) { create(:another_key, user: user) }
      let!(:deploy_key) { create(:deploy_key, user: user) }

      describe "while signed in" do
        before do
          sign_in(user)
        end

        it "does generally work" do
          get :get_keys, params: { username: user.username }

          expect(response).to be_successful
        end

        it "renders all non deploy keys separated with a new line" do
          get :get_keys, params: { username: user.username }

          expect(response.body).not_to eq('')
          expect(response.body).to eq(user.all_ssh_keys.join("\n"))

          expect(response.body).to include(key.key.sub(' dummy@gitlab.com', ''))
          expect(response.body).to include(another_key.key.sub(' dummy@gitlab.com', ''))

          expect(response.body).not_to include(deploy_key.key)
        end

        it "does not render the comment of the key" do
          get :get_keys, params: { username: user.username }
          expect(response.body).not_to match(/dummy@gitlab.com/)
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

        it "renders all non deploy keys separated with a new line" do
          get :get_keys, params: { username: user.username }

          expect(response.body).not_to eq('')
          expect(response.body).to eq(user.all_ssh_keys.join("\n"))

          expect(response.body).to include(key.key.sub(' dummy@gitlab.com', ''))
          expect(response.body).to include(another_key.key.sub(' dummy@gitlab.com', ''))

          expect(response.body).not_to include(deploy_key.key)
        end

        it "does not render the comment of the key" do
          get :get_keys, params: { username: user.username }
          expect(response.body).not_to match(/dummy@gitlab.com/)
        end

        it "responds with text/plain content type" do
          get :get_keys, params: { username: user.username }

          expect(response.content_type).to eq("text/plain")
        end
      end
    end
  end
end
