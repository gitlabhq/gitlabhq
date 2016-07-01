require 'spec_helper'

describe ApplicationController do
  describe '#check_password_expiration' do
    let(:user) { create(:user) }
    let(:controller) { ApplicationController.new }

    it 'should redirect if the user is over their password expiry' do
      user.password_expires_at = Time.new(2002)
      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).to receive(:redirect_to)
      expect(controller).to receive(:new_profile_password_path)
      controller.send(:check_password_expiration)
    end

    it 'should not redirect if the user is under their password expiry' do
      user.password_expires_at = Time.now + 20010101
      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)
      controller.send(:check_password_expiration)
    end

    it 'should not redirect if the user is over their password expiry but they are an ldap user' do
      user.password_expires_at = Time.new(2002)
      allow(user).to receive(:ldap_user?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)
      controller.send(:check_password_expiration)
    end
  end

  describe "#authenticate_user_from_token!" do
    describe "authenticating a user from a private token" do
      controller(ApplicationController) do
        def index
          render text: "authenticated"
        end
      end

      let(:user) { create(:user) }

      context "when the 'private_token' param is populated with the private token" do
        it "logs the user in" do
          get :index, private_token: user.private_token
          expect(response).to have_http_status(200)
          expect(response.body).to eq("authenticated")
        end
      end

      context "when the 'PRIVATE-TOKEN' header is populated with the private token" do
        it "logs the user in" do
          @request.headers['PRIVATE-TOKEN'] = user.private_token
          get :index
          expect(response).to have_http_status(200)
          expect(response.body).to eq("authenticated")
        end
      end

      it "doesn't log the user in otherwise" do
        @request.headers['PRIVATE-TOKEN'] = "token"
        get :index, private_token: "token", authenticity_token: "token"
        expect(response.status).not_to eq(200)
        expect(response.body).not_to eq("authenticated")
      end
    end

    describe "authenticating a user from a personal access token" do
      controller(ApplicationController) do
        def index
          render text: 'authenticated'
        end
      end

      let(:user) { create(:user) }
      let(:personal_access_token) { create(:personal_access_token, user: user) }

      context "when the 'personal_access_token' param is populated with the personal access token" do
        it "logs the user in" do
          get :index, private_token: personal_access_token.token
          expect(response).to have_http_status(200)
          expect(response.body).to eq('authenticated')
        end
      end

      context "when the 'PERSONAL_ACCESS_TOKEN' header is populated with the personal access token" do
        it "logs the user in" do
          @request.headers["PRIVATE-TOKEN"] = personal_access_token.token
          get :index
          expect(response).to have_http_status(200)
          expect(response.body).to eq('authenticated')
        end
      end

      it "doesn't log the user in otherwise" do
        get :index, private_token: "token"
        expect(response.status).not_to eq(200)
        expect(response.body).not_to eq('authenticated')
      end
    end
  end
end
