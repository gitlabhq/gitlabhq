# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Virtual Registries Packages Maven', :api, :js, feature_category: :virtual_registry do
  include_context 'file upload requests helpers'
  include_context 'with a server running the dependency proxy'

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:registry) { create(:virtual_registries_packages_maven_registry, group: group) }

  let_it_be(:external_server) do
    handler = ->(env) do
      if env['REQUEST_PATH'] == '/file' # rubocop:disable RSpec/AvoidConditionalStatements -- This is a lambda for the external server
        [200, { 'Content-Type' => 'text/plain', 'ETag' => '"etag"' }, ['File contents']]
      else
        [404, {}, []]
      end
    end

    run_server(handler)
  end

  let_it_be(:upstream) do
    create(:virtual_registries_packages_maven_upstream, registry: registry)
  end

  let(:api_path) { "/virtual_registries/packages/maven/#{registry.id}/file" }
  let(:url) { capybara_url(api(api_path)) }
  let(:authorization) do
    ActionController::HttpAuthentication::Basic.encode_credentials(user.username, personal_access_token.token)
  end

  subject(:request) { HTTParty.get(url, headers: { authorization: authorization }) }

  before do
    upstream.update_column(:url, external_server.base_url) # avoids guard that rejects local urls
    stub_config(dependency_proxy: { enabled: true })
    allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(true)
  end

  context 'with no cache entry' do
    it 'returns the file contents and create the cache entry' do
      expect { request }.to change { upstream.cache_entries.count }.by(1)
    end
  end

  context 'with a cache entry' do
    let_it_be_with_reload(:cache_entry) do
      create(
        :virtual_registries_packages_maven_cache_entry,
        :upstream_checked,
        upstream: upstream,
        relative_path: '/file',
        content_type: 'text/plain',
        upstream_etag: '"etag"'
      )
    end

    it 'returns the file contents from the cache' do
      expect(::Gitlab::HTTP).not_to receive(:head)
      expect { request }.not_to change { upstream.cache_entries.count }
      expect(request.headers[::API::VirtualRegistries::Packages::Maven::Endpoints::SHA1_CHECKSUM_HEADER])
        .to be_an_instance_of(String)
      expect(request.headers[::API::VirtualRegistries::Packages::Maven::Endpoints::MD5_CHECKSUM_HEADER])
        .to be_an_instance_of(String)
    end

    context 'with a stale cache entry' do
      before do
        cache_entry.update_column(:upstream_checked_at, 2.days.ago)
      end

      it 'returns the file contents and refresh the cache entry' do
        expect(::Gitlab::HTTP).to receive(:head).and_call_original

        expect { request }.to not_change { upstream.cache_entries.count }
          .and change { cache_entry.reload.upstream_checked_at }
      end

      context 'with a wrong etag' do
        before do
          cache_entry.update_column(:upstream_etag, 'wrong')
        end

        it 'returns the file contents and updates the cache entry' do
          expect(::Gitlab::HTTP).to receive(:head).and_call_original

          expect { request }.to not_change { upstream.cache_entries.count }
            .and change { cache_entry.reload.upstream_checked_at }
            .and change { cache_entry.reload.upstream_etag }.from('wrong').to('"etag"')
        end
      end
    end
  end
end
