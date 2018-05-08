require 'spec_helper'

describe ApplicationController do
  let(:user) { create(:user) }

  describe '#check_password_expiration' do
    let(:controller) { described_class.new }

    before do
      allow(controller).to receive(:session).and_return({})
    end

    it 'redirects if the user is over their password expiry' do
      user.password_expires_at = Time.new(2002)

      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).to receive(:redirect_to)
      expect(controller).to receive(:new_profile_password_path)

      controller.send(:check_password_expiration)
    end

    it 'does not redirect if the user is under their password expiry' do
      user.password_expires_at = Time.now + 20010101

      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)

      controller.send(:check_password_expiration)
    end

    it 'does not redirect if the user is over their password expiry but they are an ldap user' do
      user.password_expires_at = Time.new(2002)

      allow(user).to receive(:ldap_user?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)

      controller.send(:check_password_expiration)
    end

    it 'does not redirect if the user is over their password expiry but password authentication is disabled for the web interface' do
      stub_application_setting(password_authentication_enabled_for_web: false)
      stub_application_setting(password_authentication_enabled_for_git: false)
      user.password_expires_at = Time.new(2002)

      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)

      controller.send(:check_password_expiration)
    end
  end

  describe "#authenticate_user_from_personal_access_token!" do
    controller(described_class) do
      def index
        render text: 'authenticated'
      end
    end

    let(:personal_access_token) { create(:personal_access_token, user: user) }

    context "when the 'personal_access_token' param is populated with the personal access token" do
      it "logs the user in" do
        get :index, private_token: personal_access_token.token
        expect(response).to have_gitlab_http_status(200)
        expect(response.body).to eq('authenticated')
      end
    end

    context "when the 'PERSONAL_ACCESS_TOKEN' header is populated with the personal access token" do
      it "logs the user in" do
        @request.headers["PRIVATE-TOKEN"] = personal_access_token.token
        get :index
        expect(response).to have_gitlab_http_status(200)
        expect(response.body).to eq('authenticated')
      end
    end

    it "doesn't log the user in otherwise" do
      get :index, private_token: "token"
      expect(response.status).not_to eq(200)
      expect(response.body).not_to eq('authenticated')
    end
  end

  describe 'rescue from Gitlab::Git::Storage::Inaccessible' do
    controller(described_class) do
      def index
        raise Gitlab::Git::Storage::Inaccessible.new('broken', 100)
      end
    end

    it 'renders a 503 when storage is not available' do
      sign_in(create(:user))

      get :index

      expect(response.status).to eq(503)
    end

    it 'renders includes a Retry-After header' do
      sign_in(create(:user))

      get :index

      expect(response.headers['Retry-After']).to eq(100)
    end
  end

  describe 'response format' do
    controller(described_class) do
      def index
        respond_to do |format|
          format.json do
            head :ok
          end
        end
      end
    end

    before do
      sign_in user
    end

    context 'when format is handled' do
      let(:requested_format) { :json }

      it 'returns 200 response' do
        get :index, format: requested_format

        expect(response).to have_gitlab_http_status 200
      end
    end

    context 'when format is not handled' do
      it 'returns 404 response' do
        get :index

        expect(response).to have_gitlab_http_status 404
      end
    end
  end

  describe '#authenticate_user_from_rss_token' do
    describe "authenticating a user from an RSS token" do
      controller(described_class) do
        def index
          render text: 'authenticated'
        end
      end

      context "when the 'rss_token' param is populated with the RSS token" do
        context 'when the request format is atom' do
          it "logs the user in" do
            get :index, rss_token: user.rss_token, format: :atom
            expect(response).to have_gitlab_http_status 200
            expect(response.body).to eq 'authenticated'
          end
        end

        context 'when the request format is not atom' do
          it "doesn't log the user in" do
            get :index, rss_token: user.rss_token
            expect(response.status).not_to have_gitlab_http_status 200
            expect(response.body).not_to eq 'authenticated'
          end
        end
      end

      context "when the 'rss_token' param is populated with an invalid RSS token" do
        it "doesn't log the user" do
          get :index, rss_token: "token"
          expect(response.status).not_to eq 200
          expect(response.body).not_to eq 'authenticated'
        end
      end
    end
  end

  describe '#route_not_found' do
    it 'renders 404 if authenticated' do
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).to receive(:not_found)
      controller.send(:route_not_found)
    end

    it 'does redirect to login page via authenticate_user! if not authenticated' do
      allow(controller).to receive(:current_user).and_return(nil)
      expect(controller).to receive(:authenticate_user!)
      controller.send(:route_not_found)
    end
  end

  describe '#set_page_title_header' do
    let(:controller) { described_class.new }

    it 'URI encodes UTF-8 characters in the title' do
      response = double(headers: {})
      allow_any_instance_of(PageLayoutHelper).to receive(:page_title).and_return('€100 · GitLab')
      allow(controller).to receive(:response).and_return(response)

      controller.send(:set_page_title_header)

      expect(response.headers['Page-Title']).to eq('%E2%82%AC100%20%C2%B7%20GitLab')
    end
  end

  context 'two-factor authentication' do
    let(:controller) { described_class.new }

    describe '#check_two_factor_requirement' do
      subject { controller.send :check_two_factor_requirement }

      it 'does not redirect if 2FA is not required' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(false)
        expect(controller).not_to receive(:redirect_to)

        subject
      end

      it 'does not redirect if user is not logged in' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(controller).to receive(:current_user).and_return(nil)
        expect(controller).not_to receive(:redirect_to)

        subject
      end

      it 'does not redirect if user has 2FA enabled' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(controller).to receive(:current_user).twice.and_return(user)
        allow(user).to receive(:two_factor_enabled?).and_return(true)
        expect(controller).not_to receive(:redirect_to)

        subject
      end

      it 'does not redirect if 2FA setup can be skipped' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(controller).to receive(:current_user).twice.and_return(user)
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        allow(controller).to receive(:skip_two_factor?).and_return(true)
        expect(controller).not_to receive(:redirect_to)

        subject
      end

      it 'redirects to 2FA setup otherwise' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(controller).to receive(:current_user).twice.and_return(user)
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        allow(controller).to receive(:skip_two_factor?).and_return(false)
        allow(controller).to receive(:profile_two_factor_auth_path)
        expect(controller).to receive(:redirect_to)

        subject
      end
    end

    describe '#two_factor_authentication_required?' do
      subject { controller.send :two_factor_authentication_required? }

      it 'returns false if no 2FA requirement is present' do
        allow(controller).to receive(:current_user).and_return(nil)

        expect(subject).to be_falsey
      end

      it 'returns true if a 2FA requirement is set in the application settings' do
        stub_application_setting require_two_factor_authentication: true
        allow(controller).to receive(:current_user).and_return(nil)

        expect(subject).to be_truthy
      end

      it 'returns true if a 2FA requirement is set on the user' do
        user.require_two_factor_authentication_from_group = true
        allow(controller).to receive(:current_user).and_return(user)

        expect(subject).to be_truthy
      end
    end

    describe '#two_factor_grace_period' do
      subject { controller.send :two_factor_grace_period }

      it 'returns the grace period from the application settings' do
        stub_application_setting two_factor_grace_period: 23
        allow(controller).to receive(:current_user).and_return(nil)

        expect(subject).to eq 23
      end

      context 'with a 2FA requirement set on the user' do
        let(:user) { create :user, require_two_factor_authentication_from_group: true, two_factor_grace_period: 23 }

        it 'returns the user grace period if lower than the application grace period' do
          stub_application_setting two_factor_grace_period: 24
          allow(controller).to receive(:current_user).and_return(user)

          expect(subject).to eq 23
        end

        it 'returns the application grace period if lower than the user grace period' do
          stub_application_setting two_factor_grace_period: 22
          allow(controller).to receive(:current_user).and_return(user)

          expect(subject).to eq 22
        end
      end
    end

    describe '#two_factor_grace_period_expired?' do
      subject { controller.send :two_factor_grace_period_expired? }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'returns false if the user has not started their grace period yet' do
        expect(subject).to be_falsey
      end

      context 'with grace period started' do
        let(:user) { create :user, otp_grace_period_started_at: 2.hours.ago }

        it 'returns true if the grace period has expired' do
          allow(controller).to receive(:two_factor_grace_period).and_return(1)

          expect(subject).to be_truthy
        end

        it 'returns false if the grace period is still active' do
          allow(controller).to receive(:two_factor_grace_period).and_return(3)

          expect(subject).to be_falsey
        end
      end
    end

    describe '#two_factor_skippable' do
      subject { controller.send :two_factor_skippable? }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'returns false if 2FA is not required' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(false)

        expect(subject).to be_falsey
      end

      it 'returns false if the user has already enabled 2FA' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(user).to receive(:two_factor_enabled?).and_return(true)

        expect(subject).to be_falsey
      end

      it 'returns false if the 2FA grace period has expired' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        allow(controller).to receive(:two_factor_grace_period_expired?).and_return(true)

        expect(subject).to be_falsey
      end

      it 'returns true otherwise' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        allow(controller).to receive(:two_factor_grace_period_expired?).and_return(false)

        expect(subject).to be_truthy
      end
    end

    describe '#skip_two_factor?' do
      subject { controller.send :skip_two_factor? }

      it 'returns false if 2FA setup was not skipped' do
        allow(controller).to receive(:session).and_return({})

        expect(subject).to be_falsey
      end

      context 'with 2FA setup skipped' do
        before do
          allow(controller).to receive(:session).and_return({ skip_two_factor: 2.hours.from_now })
        end

        it 'returns false if the grace period has expired' do
          Timecop.freeze(3.hours.from_now) do
            expect(subject).to be_falsey
          end
        end

        it 'returns true if the grace period is still active' do
          Timecop.freeze(1.hour.from_now) do
            expect(subject).to be_truthy
          end
        end
      end
    end
  end
end
