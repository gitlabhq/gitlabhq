# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ApplicationController, feature_category: :shared do
  include TermsHelper

  let(:user) { create(:user) }

  describe '#check_password_expiration' do
    let(:controller) { described_class.new }

    before do
      allow(controller).to receive(:session).and_return({})
    end

    it 'redirects if the user is over their password expiry' do
      user.password_expires_at = Time.zone.local(2002)

      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).to receive(:redirect_to)
      expect(controller).to receive(:new_user_settings_password_path)

      controller.send(:check_password_expiration)
    end

    it 'does not redirect if the user is under their password expiry' do
      user.password_expires_at = Time.current + 20010101

      expect(user.ldap_user?).to be_falsey
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)

      controller.send(:check_password_expiration)
    end

    it 'does not redirect if the user is over their password expiry but they are an ldap user' do
      user.password_expires_at = Time.zone.local(2002)

      allow(user).to receive(:ldap_user?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)

      controller.send(:check_password_expiration)
    end

    it 'does not redirect if the user is over their password expiry but password authentication is disabled for the web interface' do
      stub_application_setting(password_authentication_enabled_for_web: false)
      stub_application_setting(password_authentication_enabled_for_git: false)
      user.password_expires_at = Time.zone.local(2002)

      allow(controller).to receive(:current_user).and_return(user)
      expect(controller).not_to receive(:redirect_to)

      controller.send(:check_password_expiration)
    end
  end

  describe '#set_current_organization' do
    let_it_be(:user) { create(:user) }
    let_it_be(:current_organization) { create(:organization, users: [user]) }

    before do
      sign_in user
    end

    controller(described_class) do
      def index; end
    end

    it 'sets current organization' do
      get :index, format: :json

      expect(Current.organization).to eq(current_organization)
    end

    context 'when multiple calls in one example are done' do
      it 'does not update the organization' do
        expect(Current).to receive(:organization=).once.and_call_original

        get :index, format: :json
        get :index, format: :json
      end
    end
  end

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
    end

    context 'with json format' do
      let(:format) { :json }

      it_behaves_like 'not setting gon variables'
    end

    context 'with atom format' do
      let(:format) { :atom }

      it_behaves_like 'not setting gon variables'
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

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when format is not handled' do
      it 'returns 404 response' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#route_not_found' do
    controller(described_class) do
      skip_before_action :authenticate_user!, only: :index

      def index
        route_not_found
      end
    end

    it 'renders 404 if authenticated' do
      sign_in(user)

      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'renders 404 if client is a search engine crawler' do
      request.env['HTTP_USER_AGENT'] = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'redirects to login page if not authenticated' do
      get :index

      expect(response).to redirect_to new_user_session_path
    end

    it 'redirects if unauthenticated and request format is unknown' do
      get :index, format: 'unknown'

      expect(response).to redirect_to new_user_session_path
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
        allow(controller).to receive(:current_user).and_return(create(:user))

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
          allow_next_instance_of(Gitlab::Auth::TwoFactorAuthVerifier) do |verifier|
            allow(verifier).to receive(:two_factor_grace_period).and_return(2)
          end

          expect(subject).to be_truthy
        end

        it 'returns false if the grace period is still active' do
          allow_next_instance_of(Gitlab::Auth::TwoFactorAuthVerifier) do |verifier|
            allow(verifier).to receive(:two_factor_grace_period).and_return(3)
          end

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
          travel_to(3.hours.from_now) do
            expect(subject).to be_falsey
          end
        end

        it 'returns true if the grace period is still active' do
          travel_to(1.hour.from_now) do
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

      expect { get :index }.not_to exceed_query_limit(control).with_threshold(1)
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      it 'redirects if the user did not accept the terms' do
        get :index

        expect(response).to have_gitlab_http_status(:found)
      end

      it 'does not redirect when the user accepted terms' do
        accept_terms(user)

        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe '#append_info_to_payload' do
    controller(described_class) do
      attr_reader :last_payload

      urgency :high, [:foo]

      def index
        render html: 'authenticated'
      end

      def foo
        render html: ''
      end

      def append_info_to_payload(payload)
        super

        @last_payload = payload
      end
    end

    before do
      routes.draw do
        get 'index' => 'anonymous#index'
        get 'foo' => 'anonymous#foo'
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

    it 'adds context metadata to the payload' do
      sign_in user

      get :index

      expect(controller.last_payload[:metadata]).to include('meta.user' => user.username)
    end

    context 'urgency information' do
      it 'adds default urgency information to the payload' do
        get :index

        expect(controller.last_payload[:request_urgency]).to eq(:default)
        expect(controller.last_payload[:target_duration_s]).to eq(1)
      end

      it 'adds customized urgency information to the payload' do
        get :foo

        expect(controller.last_payload[:request_urgency]).to eq(:high)
        expect(controller.last_payload[:target_duration_s]).to eq(0.25)
      end
    end

    it 'logs response length' do
      sign_in user

      get :index

      expect(controller.last_payload[:response_bytes]).to eq('authenticated'.bytesize)
    end

    context 'with log_response_length disabled' do
      before do
        stub_feature_flags(log_response_length: false)
      end

      it 'logs response length' do
        sign_in user

        get :index

        expect(controller.last_payload).not_to include(:response_bytes)
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

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response).to render_template('errors/not_found')
    end

    it 'renders a 403 when a message is passed to access denied' do
      get :index, params: { message: 'None shall pass' }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(response).to render_template('errors/access_denied')
    end

    it 'renders a status passed to access denied' do
      get :index, params: { status: 401 }

      expect(response).to have_gitlab_http_status(:unauthorized)
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

    it 'sets the default headers' do
      get :index

      expect(response.headers['Cache-Control']).to be_nil
      expect(response.headers['Pragma']).to be_nil
    end
  end

  describe '#stream_csv_headers' do
    controller(described_class) do
      def index
        respond_to do |format|
          format.csv do
            stream_csv_headers('test.csv')

            self.response_body = Rack::Test::UploadedFile.new('spec/fixtures/csv_comma.csv')
          end
        end
      end
    end

    subject { get :index, format: :csv }

    before do
      sign_in(user)
    end

    it 'sets no-cache headers', :aggregate_failures do
      subject

      expect(response.headers['Cache-Control']).to eq 'private, no-store'
      expect(response.headers['Expires']).to eq 'Fri, 01 Jan 1990 00:00:00 GMT'
    end

    it 'sets stream headers', :aggregate_failures do
      subject

      expect(response.headers['Content-Length']).to be nil
      expect(response.headers['X-Accel-Buffering']).to eq 'no'
      expect(response.headers['Last-Modified']).to eq '0'
    end

    it 'sets the csv specific headers', :aggregate_failures do
      subject

      expect(response.headers['Content-Type']).to eq 'text/csv; charset=utf-8; header=present'
      expect(response.headers['Content-Disposition']).to eq "attachment; filename=\"test.csv\""
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

  describe '#current_user_mode' do
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
          Gitlab::Auth::CurrentUserMode.new(user).request_admin_mode!
          Gitlab::Auth::CurrentUserMode.new(user).enable_admin_mode!(password: user.password)
        end

        it 'admin mode is set' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(Gitlab::Auth::CurrentUserMode.new(user).admin_mode?).to be(true)
        end
      end
    end
  end

  describe 'rescue_from Gitlab::Auth::IpBlocked' do
    controller(described_class) do
      skip_before_action :authenticate_user!

      def index
        raise Gitlab::Auth::IpBlocked
      end
    end

    it 'returns a 403 and logs the request' do
      expect(Gitlab::AuthLogger).to receive(:error).with({
        message: 'Rack_Attack',
        env: :blocklist,
        remote_ip: '1.2.3.4',
        request_method: 'GET',
        path: '/anonymous'
      })

      request.remote_addr = '1.2.3.4'

      get :index

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(response.body).to eq(Gitlab::Auth::IpBlocked.new.message)
    end
  end

  describe '#set_current_context' do
    controller(described_class) do
      feature_category :team_planning

      def index
        Gitlab::ApplicationContext.with_raw_context do |context|
          render json: context.to_h
        end
      end
    end

    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    it 'does not break anything when no group or project method is defined' do
      get :index

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'sets the username in the context when signed in' do
      get :index

      expect(json_response['meta.user']).to eq(user.username)
    end

    it 'sets the group if it was available' do
      group = build_stubbed(:group)
      controller.instance_variable_set(:@group, group)

      get :index, format: :json

      expect(json_response['meta.root_namespace']).to eq(group.path)
    end

    it 'sets the project if one was available' do
      project = build_stubbed(:project)
      controller.instance_variable_set(:@project, project)

      get :index, format: :json

      expect(json_response['meta.project']).to eq(project.full_path)
    end

    it 'sets the feature_category as defined in the controller' do
      get :index, format: :json

      expect(json_response['meta.feature_category']).to eq('team_planning')
    end

    it 'assigns the context to a variable for logging' do
      get :index, format: :json

      expect(assigns(:current_context)).to include('meta.user' => user.username)
    end

    it 'assigns the context when the action caused an error' do
      allow(controller).to receive(:index) { raise 'Broken' }

      expect { get :index, format: :json }.to raise_error('Broken')

      expect(assigns(:current_context)).to include('meta.user' => user.username)
    end
  end

  describe '.endpoint_id_for_action' do
    controller(described_class) {}

    it 'returns an expected endpoint id' do
      expect(controller.class.endpoint_id_for_action('hello')).to eq('AnonymousController#hello')
    end
  end

  describe '#current_user' do
    controller(described_class) do
      def index; end
    end

    let_it_be(:impersonator) { create(:user) }
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'when being impersonated' do
      before do
        allow(controller).to receive(:session).and_return({ impersonator_id: impersonator.id })
      end

      it 'returns a User with impersonator', :aggregate_failures do
        get :index

        expect(controller.current_user).to be_a(User)
        expect(controller.current_user.impersonator).to eq(impersonator)
      end
    end

    context 'when not being impersonated' do
      before do
        allow(controller).to receive(:session).and_return({})
      end

      it 'returns a User', :aggregate_failures do
        get :index

        expect(controller.current_user).to be_a(User)
        expect(controller.current_user.impersonator).to be_nil
      end
    end
  end

  describe 'locale' do
    let(:user) { create(:user, preferred_language: 'uk') }

    controller(described_class) do
      def index
        :ok
      end
    end

    before do
      sign_in(user)

      allow(Gitlab::I18n).to receive(:with_locale).and_call_original
    end

    it "sets user's locale" do
      expect(Gitlab::I18n).to receive(:with_locale).with('uk')

      get :index
    end
  end

  describe 'setting permissions-policy header' do
    controller do
      skip_before_action :authenticate_user!
      before_action :redirect_to_example, only: [:redirect]

      def index
        render html: 'It is a flock of sheep, not a floc of sheep.'
      end

      def redirect
        raise 'Should not be reached'
      end

      def redirect_to_example
        redirect_to('https://example.com')
      end
    end

    before do
      routes.draw do
        get 'index' => 'anonymous#index'
        get 'redirect' => 'anonymous#redirect'
      end
    end

    context 'with FloC enabled' do
      before do
        stub_application_setting floc_enabled: true
      end

      it 'does not set the Permissions-Policy header' do
        get :index

        expect(response.headers['Permissions-Policy']).to eq(nil)
      end
    end

    context 'with FloC disabled' do
      before do
        stub_application_setting floc_enabled: false
      end

      it 'sets the Permissions-Policy header' do
        get :index

        expect(response.headers['Permissions-Policy']).to eq('interest-cohort=()')
      end

      it 'sets the Permissions-Policy header even when redirected before_action' do
        get :redirect

        expect(response).to have_gitlab_http_status(:redirect)
        expect(response.headers['Permissions-Policy']).to eq('interest-cohort=()')
      end
    end
  end

  context 'when Gitlab::Git::ResourceExhaustedError exception is raised' do
    before do
      sign_in user
    end

    controller(described_class) do
      def index
        raise Gitlab::Git::ResourceExhaustedError.new(
          "Upstream Gitaly has been exhausted: maximum time in concurrency queue reached. Try again later", 50
        )
      end
    end

    it 'returns a error response with 503 status' do
      get :index

      expect(response).to have_gitlab_http_status(:service_unavailable)
      expect(response.headers['Retry-After']).to eq(50)
      expect(response).to render_template('errors/service_unavailable')
    end
  end

  context 'When Regexp::TimeoutError is raised' do
    before do
      sign_in user
    end

    controller(described_class) do
      def index
        raise Regexp::TimeoutError
      end
    end

    it 'returns a plaintext error response with 503 status' do
      get :index

      expect(response).to have_gitlab_http_status(:service_unavailable)
    end
  end

  describe 'cross-site request forgery protection handling' do
    describe '#handle_unverified_request' do
      it 'increments counter of invalid CSRF tokens detected' do
        stub_authentication_activity_metrics do |metrics|
          expect(metrics).to increment(:user_csrf_token_invalid_counter)
        end

        expect { described_class.new.handle_unverified_request }
          .to raise_error(ActionController::InvalidAuthenticityToken)
      end
    end
  end

  describe '#after_sign_in_path_for' do
    subject(:get_index) { get :index }

    let_it_be(:user) { create(:user) }

    controller(described_class) do
      skip_before_action :authenticate_user!

      def index
        resource = User.last
        redirect_to after_sign_in_path_for(resource)
      end
    end

    it 'redirects to root_path by default' do
      get_index

      expect(response).to redirect_to(root_path)
    end

    context 'when resource is nil' do
      before do
        allow(User).to receive(:last).and_return(nil)
      end

      it 'redirects to root_path without raising error' do
        get_index

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user has stored location to route to' do
      before do
        controller.send(:store_location_for, user, user_settings_profile_path)
      end

      it 'redirects to root_path by default' do
        get_index

        expect(response).to redirect_to(user_settings_profile_path)
      end
    end

    context 'when a redirect location is stored' do
      before do
        controller.send(:store_location_for, :redirect, user_settings_profile_path)
      end

      it 'redirects to root_path by default' do
        get_index

        expect(response).to redirect_to(user_settings_profile_path)
      end
    end
  end
end
