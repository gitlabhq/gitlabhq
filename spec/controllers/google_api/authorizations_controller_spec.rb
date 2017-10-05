require 'spec_helper'

describe GoogleApi::AuthorizationsController do
  describe 'GET|POST #callback' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:state) { namespace_project_clusters_url(project.namespace, project).to_s }
    let(:token) { 'token' }
    let(:expires_at) { 1.hour.since.strftime('%s') }

    subject { get :callback, code: 'xxx', state: state }

    before do
      sign_in(user)

      allow_any_instance_of(GoogleApi::CloudPlatform::Client)
        .to receive(:get_token).and_return([token, expires_at])
    end

    it 'sets token and expires_atin session' do
      subject

      expect(session[GoogleApi::CloudPlatform::Client.session_key_for_token])
        .to eq(token)
      expect(session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at])
        .to eq(expires_at)
    end

    context 'when redirection url is stored in state' do
      it 'redirects to the URL stored in state param' do
        expect(subject).to redirect_to(state)
      end
    end

    context 'when redirection url is not stored in state' do
      let(:state) { '' }

      it 'redirects to root_path' do
        expect(subject).to redirect_to(root_path)
      end
    end
  end
end
