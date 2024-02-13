# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GiteaController, feature_category: :importers do
  include ImportSpecHelper

  let(:provider) { :gitea }
  let(:host_url) { 'https://try.gitea.io' }

  include_context 'a GitHub-ish import controller'

  before do
    stub_application_setting(import_sources: ['gitea'])
  end

  def assign_host_url
    session[:gitea_host_url] = host_url
  end

  describe "GET new" do
    it_behaves_like 'a GitHub-ish import controller: GET new' do
      before do
        assign_host_url
      end
    end
  end

  describe "POST personal_access_token" do
    it_behaves_like 'a GitHub-ish import controller: POST personal_access_token'
  end

  describe "GET status" do
    it_behaves_like 'a GitHub-ish import controller: GET status' do
      let(:extra_assign_expectations) { { gitea_host_url: host_url } }

      before do
        assign_host_url
      end

      it "requests provider repos list" do
        expect(stub_client(repos: [], orgs: [])).to receive(:repos)

        get :status

        expect(response).to have_gitlab_http_status(:ok)
      end

      shared_examples "unacceptable url" do |url, expected_error|
        let(:host_url) { url }

        it 'denies network request' do
          get :status, format: :json

          expect(controller).to redirect_to(new_import_url)
          expect(flash[:alert]).to eq("Specified URL cannot be used: \"#{expected_error}\"")
        end
      end

      context 'when host url is local or not http' do
        include_examples 'unacceptable url', 'https://localhost:3000', 'Only allowed schemes are http, https'
        include_examples 'unacceptable url', 'http://192.168.0.1', 'Only allowed schemes are http, https'
        include_examples 'unacceptable url', 'ftp://testing', 'Only allowed schemes are http, https'
      end

      context 'when DNS Rebinding protection is enabled' do
        let(:token) { 'gitea token' }

        let(:ip_uri) { 'http://167.99.148.217' }
        let(:uri) { 'try.gitea.io' }
        let(:https_uri) { "https://#{uri}" }
        let(:http_uri) { "http://#{uri}" }

        before do
          session[:gitea_access_token] = token

          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!).with(https_uri, anything).and_return([Addressable::URI.parse(https_uri), uri])
          allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!).with(http_uri, anything).and_return([Addressable::URI.parse(ip_uri), uri])

          allow(Gitlab::LegacyGithubImport::Client).to receive(:new).and_return(double('Gitlab::LegacyGithubImport::Client', repos: [], orgs: []))
        end

        context 'when provided host url is using https' do
          let(:host_url) { https_uri }

          it 'uses unchanged host url to send request to Gitea' do
            expect(Gitlab::LegacyGithubImport::Client).to receive(:new).with(token, host: https_uri, api_version: 'v1', hostname: 'try.gitea.io')

            get :status, format: :json

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when provided host url is using http' do
          let(:host_url) { http_uri }

          it 'uses changed host url to send request to Gitea' do
            expect(Gitlab::LegacyGithubImport::Client).to receive(:new).with(token, host: 'http://167.99.148.217', api_version: 'v1', hostname: 'try.gitea.io')

            get :status, format: :json

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end

  describe 'POST create' do
    it_behaves_like 'a GitHub-ish import controller: POST create' do
      before do
        assign_host_url
      end
    end

    it_behaves_like 'project import rate limiter'
  end

  describe "GET realtime_changes" do
    it_behaves_like 'a GitHub-ish import controller: GET realtime_changes' do
      before do
        assign_host_url
      end
    end
  end
end
