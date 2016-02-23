require 'spec_helper'

describe Profiles::KeysController do
  let(:user)    { create(:user) }

  describe "#get_keys" do
    describe "non existant user" do
      it "should generally not work" do
        get :get_keys, username: 'not-existent'

        expect(response).not_to be_success
      end
    end

    describe "user with no keys" do
      it "should generally work" do
        get :get_keys, username: user.username

        expect(response).to be_success
      end

      it "should render all keys separated with a new line" do
        get :get_keys, username: user.username

        expect(response.body).to eq("")
      end

      it "should respond with text/plain content type" do
        get :get_keys, username: user.username
        expect(response.content_type).to eq("text/plain")
      end
    end

    describe "user with keys" do
      before do
        user.keys << create(:key)
        user.keys << create(:another_key)
      end

      it "should generally work" do
        get :get_keys, username: user.username

        expect(response).to be_success
      end

      it "should render all keys separated with a new line" do
        get :get_keys, username: user.username

        expect(response.body).not_to eq("")
        expect(response.body).to eq(user.all_ssh_keys.join("\n"))

        # Unique part of key 1
        expect(response.body).to match(/PWx6WM4lhHNedGfBpPJNPpZ/)
        # Key 2
        expect(response.body).to match(/AQDmTillFzNTrrGgwaCKaSj/)
      end

      it "should not render the comment of the key" do
        get :get_keys, username: user.username

        expect(response.body).not_to match(/dummy@gitlab.com/)
      end

      it "should respond with text/plain content type" do
        get :get_keys, username: user.username
        expect(response.content_type).to eq("text/plain")
      end
    end
  end
end
