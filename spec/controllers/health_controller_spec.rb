# frozen_string_literal: true

require 'spec_helper'

describe HealthController do
  include StubENV

  let(:token) { Gitlab::CurrentSettings.health_check_access_token }
  let(:whitelisted_ip) { '127.0.0.1' }
  let(:not_whitelisted_ip) { '127.0.0.2' }

  before do
    allow(Settings.monitoring).to receive(:ip_whitelist).and_return([whitelisted_ip])
    stub_storage_settings({}) # Hide the broken storage
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe '#readiness' do
    shared_context 'endpoint responding with readiness data' do
      let(:request_params) { {} }

      subject { get :readiness, params: request_params }

      it 'responds with readiness checks data' do
        subject

        expect(json_response['db_check']['status']).to eq('ok')
        expect(json_response['cache_check']['status']).to eq('ok')
        expect(json_response['queues_check']['status']).to eq('ok')
        expect(json_response['shared_state_check']['status']).to eq('ok')
        expect(json_response['gitaly_check']['status']).to eq('ok')
      end
    end

    context 'accessed from whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it_behaves_like 'endpoint responding with readiness data'
    end

    context 'accessed from not whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(not_whitelisted_ip)
      end

      it 'responds with resource not found' do
        get :readiness

        expect(response.status).to eq(404)
      end

      context 'accessed with valid token' do
        context 'token passed in request header' do
          before do
            request.headers['TOKEN'] = token
          end

          it_behaves_like 'endpoint responding with readiness data'
        end
      end

      context 'token passed as URL param' do
        it_behaves_like 'endpoint responding with readiness data' do
          let(:request_params) { { token: token } }
        end
      end
    end
  end

  describe '#liveness' do
    shared_context 'endpoint responding with liveness data' do
      subject { get :liveness }

      it 'responds with liveness checks data' do
        subject

        expect(json_response['db_check']['status']).to eq('ok')
        expect(json_response['cache_check']['status']).to eq('ok')
        expect(json_response['queues_check']['status']).to eq('ok')
        expect(json_response['shared_state_check']['status']).to eq('ok')
      end
    end

    context 'accessed from whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it_behaves_like 'endpoint responding with liveness data'
    end

    context 'accessed from not whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(not_whitelisted_ip)
      end

      it 'responds with resource not found' do
        get :liveness

        expect(response.status).to eq(404)
      end

      context 'accessed with valid token' do
        context 'token passed in request header' do
          before do
            request.headers['TOKEN'] = token
          end

          it_behaves_like 'endpoint responding with liveness data'
        end

        context 'token passed as URL param' do
          it_behaves_like 'endpoint responding with liveness data' do
            subject { get :liveness, params: { token: token } }
          end
        end
      end
    end
  end
end
