require 'spec_helper'

describe GoogleApi::AuthorizationsController do
  describe 'GET|POST #callback' do
    let(:user) { create(:user) }
    let(:token) { 'token' }
    let(:expires_at) { 1.hour.since.strftime('%s') }

    subject { get :callback, code: 'xxx', state: @state }

    before do
      sign_in(user)

      allow_any_instance_of(GoogleApi::CloudPlatform::Client)
        .to receive(:get_token).and_return([token, expires_at])
    end

    it 'sets token and expires_at in session' do
      subject

      expect(session[GoogleApi::CloudPlatform::Client.session_key_for_token])
        .to eq(token)
      expect(session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at])
        .to eq(expires_at)
    end

    context 'when redirect uri key is stored in state' do
      set(:project) { create(:project) }
      let(:redirect_uri) { project_clusters_url(project).to_s }

      before do
        @state = GoogleApi::CloudPlatform::Client
          .new_session_key_for_redirect_uri do |key|
          session[key] = redirect_uri
        end
      end

      it 'redirects to the URL stored in state param' do
        expect(subject).to redirect_to(redirect_uri)
      end
    end

    context 'when redirection url is not stored in state' do
      it 'redirects to root_path' do
        expect(subject).to redirect_to(root_path)
      end
    end
  end
end
