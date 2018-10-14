# frozen_string_literal: true

# extract new and create_gcp, create_user ?

require 'spec_helper'

describe GcpSession do
  controller(ApplicationController) do
    # `described_class` is not available in this context
    include GcpSession # rubocop:disable RSpec/DescribedClass
  end

  describe '#token_in_session' do
    subject { controller_class.new.token_in_session }

    it 'runs' do
      subject
    end
  end

  describe '#validated_gcp_token' do
    context 'when access token is expired' do
      before do
        stub_google_api_expired_token
      end

      it { expect(@valid_gcp_token).to be_falsey }
    end

    context 'when access token is not stored in session' do
      it { expect(@valid_gcp_token).to be_falsey }
    end
  end

  describe '#gcp_authorize_url' do
    context 'when omniauth has been configured' do
      let(:key) { 'secret-key' }
      let(:session_key_for_redirect_uri) do
        GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(key)
      end

      before do
        allow(SecureRandom).to receive(:hex).and_return(key)
      end

      it 'has authorize_url' do
        go

        expect(assigns(:authorize_url)).to include(key)
        expect(session[session_key_for_redirect_uri]).to eq(new_project_cluster_path(project))
      end
    end

    context 'when omniauth has not configured' do
      before do
        stub_omniauth_setting(providers: [])
      end

      it 'does not have authorize_url' do
        go

        expect(assigns(:authorize_url)).to be_nil
      end
    end
  end


end
