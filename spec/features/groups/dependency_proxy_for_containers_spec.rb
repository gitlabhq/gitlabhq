# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Dependency Proxy for containers', :js, feature_category: :virtual_registry do
  include DependencyProxyHelpers

  include_context 'file upload requests helpers'
  include_context 'with a server running the dependency proxy'

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:sha) { 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4' }
  let_it_be(:content) { fixture_file_upload("spec/fixtures/dependency_proxy/#{sha}.gz").read }

  let(:image) { 'alpine' }
  let(:url) { capybara_url("/v2/#{group.full_path}/dependency_proxy/containers/#{image}/blobs/sha256:#{sha}") }
  let(:token) { 'token' }
  let(:headers) { { 'Authorization' => "Bearer #{build_jwt(user).encoded}" } }

  subject(:response) do
    HTTParty.get(url, headers: headers)
  end

  let_it_be(:external_server) do
    handler = ->(env) do
      if env['REQUEST_PATH'] == '/token'
        [200, {}, [{ token: 'token' }.to_json]]
      else
        [200, {}, [content]]
      end
    end

    run_server(handler)
  end

  before do
    stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
    stub_config(dependency_proxy: { enabled: true })
    group.add_developer(user)

    stub_const("DependencyProxy::Registry::AUTH_URL", external_server.base_url)
    stub_const("DependencyProxy::Registry::LIBRARY_URL", external_server.base_url)
  end

  shared_examples 'responds with the file' do
    it 'sends file' do
      expect(subject.code).to eq(200)
      expect(subject.body).to eq(content)
      expect(subject.headers.to_h).to include(
        "content-type" => ["application/gzip"],
        "content-disposition" => ["attachment; filename=\"#{sha}.gz\"; filename*=UTF-8''#{sha}.gz"],
        "content-length" => ["32"]
      )
    end
  end

  shared_examples 'caches the file' do
    it 'caches the file' do
      expect { subject }.to change {
        group.dependency_proxy_blobs.count
      }.from(0).to(1)

      expect(subject.code).to eq(200)
      expect(group.dependency_proxy_blobs.first.file.read).to eq(content)
    end
  end

  shared_examples 'returns not found' do
    it 'returns not found' do
      expect(subject.code).to eq(404)
    end
  end

  context 'fetching a blob' do
    context 'when the blob is cached for the group' do
      let!(:dependency_proxy_blob) { create(:dependency_proxy_blob, group: group) }

      # When authenticating with a job token, the encoded token is the same as
      # that built when authenticating with a user
      context 'with a user or a job token' do
        let_it_be(:headers) { { 'Authorization' => "Bearer #{build_jwt(user).encoded}" } }

        it_behaves_like 'responds with the file'
      end

      context 'with a personal access token' do
        let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
        let_it_be(:headers) { { 'Authorization' => "Bearer #{build_jwt(personal_access_token).encoded}" } }

        it_behaves_like 'responds with the file'
      end

      context 'with a group access token' do
        context 'when a member of the group' do
          let_it_be(:group_bot_user) { create(:user, :project_bot, guest_of: group) }
          let_it_be(:group_access_token) { create(:personal_access_token, user: group_bot_user) }
          let_it_be(:headers) { { 'Authorization' => "Bearer #{build_jwt(group_access_token).encoded}" } }

          it_behaves_like 'responds with the file'
        end

        context 'when not a member of the group' do
          let_it_be(:group_bot_user) { create(:user, :project_bot) }
          let_it_be(:group_access_token) { create(:personal_access_token, user: group_bot_user) }
          let_it_be(:headers) { { 'Authorization' => "Bearer #{build_jwt(group_access_token).encoded}" } }

          it_behaves_like 'returns not found'
        end
      end

      context 'with a group deploy token' do
        before do
          create(:group_deploy_token, group: group, deploy_token: deploy_token)
        end

        context 'with sufficient scopes' do
          let_it_be(:deploy_token) { create(:deploy_token, :group, :dependency_proxy_scopes) }
          let_it_be(:headers) { { 'Authorization' => "Bearer #{build_jwt(deploy_token).encoded}" } }

          it_behaves_like 'responds with the file'
        end

        context 'with insufficient scopes' do
          let_it_be(:deploy_token) { create(:deploy_token, :group) }
          let_it_be(:headers) { { 'Authorization' => "Bearer #{build_jwt(deploy_token).encoded}" } }

          it_behaves_like 'returns not found'
        end
      end
    end
  end

  context 'when the blob must be downloaded' do
    it_behaves_like 'responds with the file'
    it_behaves_like 'caches the file'
  end

  context 'when calling the authentication endpoint' do
    let(:url) { capybara_url('/v2') }

    it 'does not set session cookies' do
      expect(response.headers).not_to include('set-cookie')
    end
  end
end
