# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthCheckController, :request_store, :use_clean_rails_memory_store_caching do
  include StubENV

  let(:xml_response) { Hash.from_xml(response.body)['hash'] }
  let(:token) { Gitlab::CurrentSettings.health_check_access_token }
  let(:whitelisted_ip) { '127.0.0.1' }
  let(:not_whitelisted_ip) { '127.0.0.2' }

  before do
    allow(Settings.monitoring).to receive(:ip_whitelist).and_return([whitelisted_ip])
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'GET #index' do
    context 'when services are up but accessed from outside whitelisted ips' do
      before do
        allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(not_whitelisted_ip)
      end

      it 'returns a not found page' do
        get :index

        expect(response).to be_not_found
      end

      context 'when services are accessed with token' do
        it 'supports passing the token in the header' do
          request.headers['TOKEN'] = token

          get :index

          expect(response).to be_successful
          expect(response.media_type).to eq 'text/plain'
        end

        it 'supports passing the token in query params' do
          get :index, params: { token: token }

          expect(response).to be_successful
          expect(response.media_type).to eq 'text/plain'
        end
      end
    end

    context 'when services are up and accessed from whitelisted ips' do
      before do
        allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it 'supports successful plaintext response' do
        get :index

        expect(response).to be_successful
        expect(response.media_type).to eq 'text/plain'
      end

      it 'supports successful json response' do
        get :index, format: :json

        expect(response).to be_successful
        expect(response.media_type).to eq 'application/json'
        expect(json_response['healthy']).to be true
      end

      it 'supports successful xml response' do
        get :index, format: :xml

        expect(response).to be_successful
        expect(response.media_type).to eq 'application/xml'
        expect(xml_response['healthy']).to be true
      end

      it 'supports successful responses for specific checks' do
        get :index, params: { checks: 'email' }, format: :json

        expect(response).to be_successful
        expect(response.media_type).to eq 'application/json'
        expect(json_response['healthy']).to be true
      end

      context 'if the request IP was mapped to an IPv6' do
        before do
          allow(Gitlab::RequestContext.instance)
            .to receive(:client_ip)
            .and_return("::ffff:#{whitelisted_ip}")
        end

        it 'supports successful plaintext response' do
          get :index

          expect(response).to be_successful
          expect(response.media_type).to eq 'text/plain'
        end
      end
    end

    context 'when a service is down but NO access token' do
      it 'returns a not found page' do
        get :index

        expect(response).to be_not_found
      end
    end

    context 'when a service is down and an endpoint is accessed from whitelisted ip' do
      before do
        allow(::HealthCheck).to receive(:include_error_in_response_body).and_return(true)
        allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it 'supports failure plaintext response' do
        expect(HealthCheck::Utils).to receive(:process_checks).with(['standard']).and_return('The server is on fire')

        get :index

        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(response.media_type).to eq 'text/plain'
        expect(response.body).to include('The server is on fire')
      end

      it 'supports failure json response' do
        expect(HealthCheck::Utils).to receive(:process_checks).with(['standard']).and_return('The server is on fire')

        get :index, format: :json

        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(response.media_type).to eq 'application/json'
        expect(json_response['healthy']).to be false
        expect(json_response['message']).to include('The server is on fire')
      end

      it 'supports failure xml response' do
        expect(HealthCheck::Utils).to receive(:process_checks).with(['standard']).and_return('The server is on fire')

        get :index, format: :xml

        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(response.media_type).to eq 'application/xml'
        expect(xml_response['healthy']).to be false
        expect(xml_response['message']).to include('The server is on fire')
      end

      it 'supports failure responses for specific checks' do
        expect(HealthCheck::Utils).to receive(:process_checks).with(['email']).and_return('Email is on fire')

        get :index, params: { checks: 'email' }, format: :json

        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(response.media_type).to eq 'application/json'
        expect(json_response['healthy']).to be false
        expect(json_response['message']).to include('Email is on fire')
      end
    end
  end
end
