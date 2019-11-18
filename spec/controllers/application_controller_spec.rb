# frozen_string_literal: true
require 'spec_helper'

describe ApplicationController do
  include TermsHelper

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

  it_behaves_like 'a Trackable Controller'

  describe '#add_gon_variables' do
    before do
      Gon.clear
      sign_in user
    end

    controller(described_class) do
      def index
        render json: Gon.all_variables
      end
    end

    shared_examples 'setting gon variables' do
      it 'sets gon variables' do
        get :index, format: format

        expect(json_response.size).not_to be_zero
      end
    end

    shared_examples 'not setting gon variables' do
      it 'does not set gon variables' do
        get :index, format: format

        expect(json_response.size).to be_zero
      end
    end

    context 'with html format' do
      let(:format) { :html }

      it_behaves_like 'setting gon variables'

      context 'for peek requests' do
        before do
          request.path = '/-/peek'
        end

        it_behaves_like 'not setting gon variables'
      end
    end

    context 'with json format' do
      let(:format) { :json }

      it_behaves_like 'not setting gon variables'
    end
  end

  describe 'session expiration' do
    controller(described_class) do
      # The anonymous controller will report 401 and fail to run any actions.
      # Normally, GitLab will just redirect you to sign in.
      skip_before_action :authenticate_user!, only: :index

      def index
        render html: 'authenticated'
      end
    end

    context 'authenticated user' do
      it 'does not set the expire_after option' do
        sign_in(create(:user))

        get :index

        expect(request.env['rack.session.options'][:expire_after]).to be_nil
      end
    end

    context 'unauthenticated user' do
      it 'sets the expire_after option' do
        get :index

        expect(request.env['rack.session.options'][:expire_after]).to eq(Settings.gitlab['unauthenticated_session_expire_delay'])
      end
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

  describe '#route_not_found' do
    controller(described_class) do
      def index
        route_not_found
      end
    end

    it 'renders 404 if authenticated' do
      sign_in(user)

      get :index

      expect(response).to have_gitlab_http_status(404)
    end

    it 'redirects to login page if not authenticated' do
      get :index

      expect(response).to redirect_to new_user_session_path
    end

    context 'request format is unknown' do
      it 'redirects if unauthenticated' do
        get :index, format: 'unknown'

        expect(response).to redirect_to new_user_session_path
      end

      it 'returns a 401 if the feature flag is disabled' do
        stub_feature_flags(devise_redirect_unknown_formats: false)

        get :index, format: 'unknown'

        expect(response).to have_gitlab_http_status(401)
      end
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

      it 'does not redirect if user has temporary oauth email' do
        oauth_user = create(:user, email: 'temp-email-for-oauth@email.com')
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(controller).to receive(:current_user).and_return(oauth_user)

        expect(controller).not_to receive(:redirect_to)

        subject
      end

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
        allow(controller).to receive(:current_user).thrice.and_return(user)
        allow(user).to receive(:two_factor_enabled?).and_return(true)

        expect(controller).not_to receive(:redirect_to)

        subject
      end

      it 'does not redirect if 2FA setup can be skipped' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(controller).to receive(:current_user).thrice.and_return(user)
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        allow(controller).to receive(:skip_two_factor?).and_return(true)

        expect(controller).not_to receive(:redirect_to)

        subject
      end

      it 'redirects to 2FA setup otherwise' do
        allow(controller).to receive(:two_factor_authentication_required?).and_return(true)
        allow(controller).to receive(:current_user).thrice.and_return(user)
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

      it 'returns true if user has signed up using omniauth-ultraauth' do
        user = create(:omniauth_user, provider: 'ultraauth')
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

  context 'deactivated user' do
    controller(described_class) do
      def index
        render html: 'authenticated'
      end
    end

    before do
      sign_in user
      user.deactivate
    end

    it 'signs out a deactivated user' do
      get :index
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq('Your account has been deactivated by your administrator. Please log back in to reactivate your account.')
    end
  end

  context 'terms' do
    controller(described_class) do
      def index
        render html: 'authenticated'
      end
    end

    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      sign_in user
    end

    it 'does not query more when terms are enforced' do
      control = ActiveRecord::QueryRecorder.new { get :index }

      enforce_terms

      expect { get :index }.not_to exceed_query_limit(control)
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      it 'redirects if the user did not accept the terms' do
        get :index

        expect(response).to have_gitlab_http_status(302)
      end

      it 'does not redirect when the user accepted terms' do
        accept_terms(user)

        get :index

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe '#append_info_to_payload' do
    controller(described_class) do
      attr_reader :last_payload

      def index
        render html: 'authenticated'
      end

      def append_info_to_payload(payload)
        super

        @last_payload = payload
      end
    end

    it 'does not log errors with a 200 response' do
      get :index

      expect(controller.last_payload.has_key?(:response)).to be_falsey
    end

    it 'does log correlation id' do
      Labkit::Correlation::CorrelationId.use_id('new-id') do
        get :index
      end

      expect(controller.last_payload).to include('correlation_id' => 'new-id')
    end

    context '422 errors' do
      it 'logs a response with a string' do
        response = spy(ActionDispatch::Response, status: 422, body: 'Hello world', content_type: 'application/json', cookies: {})
        allow(controller).to receive(:response).and_return(response)
        get :index

        expect(controller.last_payload[:response]).to eq('Hello world')
      end

      it 'logs a response with an array' do
        body = ['I want', 'my hat back']
        response = spy(ActionDispatch::Response, status: 422, body: body, content_type: 'application/json', cookies: {})
        allow(controller).to receive(:response).and_return(response)
        get :index

        expect(controller.last_payload[:response]).to eq(body)
      end

      it 'does not log a string with an empty body' do
        response = spy(ActionDispatch::Response, status: 422, body: nil, content_type: 'application/json', cookies: {})
        allow(controller).to receive(:response).and_return(response)
        get :index

        expect(controller.last_payload.has_key?(:response)).to be_falsey
      end

      it 'does not log an HTML body' do
        response = spy(ActionDispatch::Response, status: 422, body: 'This is a test', content_type: 'application/html', cookies: {})
        allow(controller).to receive(:response).and_return(response)
        get :index

        expect(controller.last_payload.has_key?(:response)).to be_falsey
      end
    end
  end

  describe '#access_denied' do
    controller(described_class) do
      def index
        access_denied!(params[:message], params[:status])
      end
    end

    before do
      sign_in user
    end

    it 'renders a 404 without a message' do
      get :index

      expect(response).to have_gitlab_http_status(404)
      expect(response).to render_template('errors/not_found')
    end

    it 'renders a 403 when a message is passed to access denied' do
      get :index, params: { message: 'None shall pass' }

      expect(response).to have_gitlab_http_status(403)
      expect(response).to render_template('errors/access_denied')
    end

    it 'renders a status passed to access denied' do
      get :index, params: { status: 401 }

      expect(response).to have_gitlab_http_status(401)
    end
  end

  context 'when invalid UTF-8 parameters are received' do
    controller(described_class) do
      def index
        params[:text].split(' ')

        render json: :ok
      end
    end

    before do
      sign_in user
    end

    context 'html' do
      subject { get :index, params: { text: "hi \255" } }

      it 'renders 412' do
        expect { subject }.to raise_error(ActionController::BadRequest)
      end
    end

    context 'js' do
      subject { get :index, format: :js, params: { text: "hi \255" } }

      it 'renders 412' do
        expect { subject }.to raise_error(ActionController::BadRequest)
      end
    end
  end

  context 'X-GitLab-Custom-Error header' do
    before do
      sign_in user
    end

    context 'given a 422 error page' do
      controller do
        def index
          render 'errors/omniauth_error', layout: 'errors', status: :unprocessable_entity
        end
      end

      it 'sets a custom header' do
        get :index

        expect(response.headers['X-GitLab-Custom-Error']).to eq '1'
      end
    end

    context 'given a 500 error page' do
      controller do
        def index
          render 'errors/omniauth_error', layout: 'errors', status: :internal_server_error
        end
      end

      it 'sets a custom header' do
        get :index

        expect(response.headers['X-GitLab-Custom-Error']).to eq '1'
      end
    end

    context 'given a 200 success page' do
      controller do
        def index
          render 'errors/omniauth_error', layout: 'errors', status: :ok
        end
      end

      it 'does not set a custom header' do
        get :index

        expect(response.headers['X-GitLab-Custom-Error']).to be_nil
      end
    end

    context 'given a json response' do
      controller do
        def index
          render json: {}, status: :unprocessable_entity
        end
      end

      it 'sets a custom header' do
        get :index, format: :json

        expect(response.headers['X-GitLab-Custom-Error']).to eq '1'
      end

      context 'for html request' do
        it 'sets a custom header' do
          get :index

          expect(response.headers['X-GitLab-Custom-Error']).to eq '1'
        end
      end

      context 'for 200 response' do
        controller do
          def index
            render json: {}, status: :ok
          end
        end

        it 'does not set a custom header' do
          get :index, format: :json

          expect(response.headers['X-GitLab-Custom-Error']).to be_nil
        end
      end
    end
  end

  context 'control headers' do
    controller(described_class) do
      def index
        render json: :ok
      end
    end

    context 'user not logged in' do
      it 'sets the default headers' do
        get :index

        expect(response.headers['Cache-Control']).to be_nil
      end
    end

    context 'user logged in' do
      it 'sets the default headers' do
        sign_in(user)

        get :index

        expect(response.headers['Cache-Control']).to eq 'max-age=0, private, must-revalidate, no-store'
      end

      it 'does not set the "no-store" header for XHR requests' do
        sign_in(user)

        get :index, xhr: true

        expect(response.headers['Cache-Control']).to eq 'max-age=0, private, must-revalidate'
      end
    end
  end

  context 'Gitlab::Session' do
    controller(described_class) do
      prepend_before_action do
        authenticate_sessionless_user!(:rss)
      end

      def index
        if Gitlab::Session.current
          head :created
        else
          head :not_found
        end
      end
    end

    it 'is set on web requests' do
      sign_in(user)

      get :index

      expect(response).to have_gitlab_http_status(:created)
    end

    context 'with sessionless user' do
      it 'is not set' do
        personal_access_token = create(:personal_access_token, user: user)

        get :index, format: :atom, params: { private_token: personal_access_token.token }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#current_user_mode', :do_not_mock_admin_mode do
    include_context 'custom session'

    controller(described_class) do
      def index
        render html: 'authenticated'
      end
    end

    before do
      allow(ActiveSession).to receive(:list_sessions).with(user).and_return([session])

      sign_in(user)
      get :index
    end

    context 'with a regular user' do
      it 'admin mode is not set' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Auth::CurrentUserMode.new(user).admin_mode?).to be(false)
      end
    end

    context 'with an admin user' do
      let(:user) { create(:admin) }

      it 'admin mode is not set' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Auth::CurrentUserMode.new(user).admin_mode?).to be(false)
      end

      context 'that re-authenticated' do
        before do
          Gitlab::Auth::CurrentUserMode.new(user).enable_admin_mode!(password: user.password)
        end

        it 'admin mode is set' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(Gitlab::Auth::CurrentUserMode.new(user).admin_mode?).to be(true)
        end
      end
    end
  end

  describe '#required_signup_info' do
    controller(described_class) do
      def index; end
    end

    let(:user) { create(:user) }
    let(:experiment_enabled) { true }

    before do
      stub_experiment_for_user(signup_flow: experiment_enabled)
    end

    context 'experiment enabled and user with required role' do
      before do
        user.set_role_required!
        sign_in(user)
        get :index
      end

      it { is_expected.to redirect_to users_sign_up_welcome_path }
    end

    context 'experiment enabled and user without a required role' do
      before do
        sign_in(user)
        get :index
      end

      it { is_expected.not_to redirect_to users_sign_up_welcome_path }
    end

    context 'experiment disabled' do
      let(:experiment_enabled) { false }

      before do
        user.set_role_required!
        sign_in(user)
        get :index
      end

      it { is_expected.not_to redirect_to users_sign_up_welcome_path }
    end
  end
end
