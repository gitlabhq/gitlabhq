# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MirrorsController, feature_category: :source_code_management do
  include ReactiveCachingHelpers

  shared_examples 'only admin is allowed when mirroring is disabled' do
    let(:subject_action) { raise 'subject_action is required' }
    let(:user) { project.first_owner }
    let(:project_settings_path) { project_settings_repository_path(project, anchor: 'js-push-remote-settings') }

    context 'when project mirroring is enabled' do
      it 'allows requests from a maintainer' do
        sign_in(user)

        subject_action
        expect(response).to redirect_to(project_settings_path)
      end

      it 'allows requests from an admin user' do
        user.update!(admin: true)
        sign_in(user)

        subject_action
        expect(response).to redirect_to(project_settings_path)
      end
    end

    context 'when project mirroring is disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      it 'disallows requests from a maintainer' do
        sign_in(user)

        subject_action
        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'allows requests from an admin user' do
          user.update!(admin: true)
          sign_in(user)

          subject_action
          expect(response).to redirect_to(project_settings_path)
        end
      end

      context 'when admin mode is disabled' do
        it 'disallows requests from an admin user' do
          user.update!(admin: true)
          sign_in(user)

          subject_action
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'Access control' do
    let(:project) { create(:project, :repository) }

    describe '#update' do
      include_examples 'only admin is allowed when mirroring is disabled' do
        let(:subject_action) do
          do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com' } })
        end
      end
    end

    describe '#update_now' do
      include_examples 'only admin is allowed when mirroring is disabled' do
        let(:options) { { namespace_id: project.namespace, project_id: project } }

        let(:subject_action) do
          get :update_now, params: options.merge(sync_remote: true)
        end
      end
    end
  end

  describe 'setting up a remote mirror' do
    let_it_be(:project) { create(:project, :repository) }

    context 'when the current project is not a mirror' do
      it 'allows to create a remote mirror' do
        sign_in(project.first_owner)

        expect do
          do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com' } })
        end.to change { RemoteMirror.count }.to(1)
      end
    end

    context 'setting up SSH public-key authentication' do
      let(:ssh_mirror_attributes) do
        {
          'auth_method' => 'ssh_public_key',
          'url' => 'ssh://git@example.com',
          'ssh_known_hosts' => 'test'
        }
      end

      it 'processes a successful update' do
        sign_in(project.first_owner)
        do_put(project, remote_mirrors_attributes: { '0' => ssh_mirror_attributes })

        expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-push-remote-settings'))

        expect(RemoteMirror.count).to eq(1)
        expect(RemoteMirror.first).to have_attributes(
          auth_method: 'ssh_public_key',
          url: 'ssh://git@example.com',
          ssh_public_key: match(/\Assh-rsa /),
          ssh_known_hosts: 'test'
        )
      end
    end
  end

  describe '#update' do
    let(:project) { create(:project, :repository, :remote_mirror) }

    before do
      sign_in(project.first_owner)
    end

    context 'With valid URL for a push' do
      let(:remote_mirror_attributes) do
        { "0" => { "enabled" => "0", url: 'https://updated.example.com' } }
      end

      it 'processes a successful update' do
        do_put(project, remote_mirrors_attributes: remote_mirror_attributes)

        expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-push-remote-settings'))
        expect(flash[:notice]).to match(/successfully updated/)
      end

      it 'creates a RemoteMirror object' do
        expect { do_put(project, remote_mirrors_attributes: remote_mirror_attributes) }.to change(RemoteMirror, :count).by(1)
      end

      context 'with json format' do
        it 'processes a successful update' do
          do_put(project, { remote_mirrors_attributes: remote_mirror_attributes }, { format: :json })

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include(
            'id' => project.id,
            'remote_mirrors_attributes' => a_kind_of(Array)
          )
        end
      end
    end

    context 'With invalid URL for a push' do
      let(:remote_mirror_attributes) do
        { "0" => { "enabled" => "0", url: 'ftp://invalid.invalid' } }
      end

      it 'processes an unsuccessful update' do
        do_put(project, remote_mirrors_attributes: remote_mirror_attributes)

        expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-push-remote-settings'))
        expect(flash[:alert]).to match(/Only allowed schemes are/)
      end

      it 'does not create a RemoteMirror object' do
        expect { do_put(project, remote_mirrors_attributes: remote_mirror_attributes) }.not_to change(RemoteMirror, :count)
      end

      context 'when service returns an error' do
        before do
          allow(::RemoteMirrors::CreateService).to receive(:new).and_return(
            instance_double('RemoteMirrors::CreateService', execute: ServiceResponse.error(message: 'ServiceError'))
          )
        end

        it 'processes an unsuccessful update' do
          do_put(project, remote_mirrors_attributes: remote_mirror_attributes)

          expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-push-remote-settings'))
          expect(flash[:alert]).to eq('ServiceError')
        end
      end

      context 'with json format' do
        it 'processes an unsuccessful update' do
          do_put(project, { remote_mirrors_attributes: remote_mirror_attributes }, { format: :json })

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['url']).to include(/Only allowed schemes are/)
        end
      end
    end

    context 'when user deletes the remote mirror' do
      let(:remote_mirror_attributes) { { id: mirror_id, _destroy: 1 } }
      let(:mirror_id) { project.remote_mirrors.first.id }

      it 'processes a successful delete' do
        expect { do_put(project, remote_mirrors_attributes: remote_mirror_attributes) }.to change(RemoteMirror, :count).by(-1)

        expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-push-remote-settings'))
        expect(flash[:notice]).to match(/successfully updated/)
      end

      context 'when mirror id is not found' do
        let(:mirror_id) { non_existing_record_id }

        it 'returns a 404 error' do
          expect { do_put(project, remote_mirrors_attributes: remote_mirror_attributes) }.not_to change(RemoteMirror, :count)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when request is invalid' do
      context 'with html format' do
        it 'returns an error' do
          do_put(project, { wrong: :params })

          expect(response).to redirect_to(project_settings_repository_path(project, anchor: 'js-push-remote-settings'))
          expect(flash[:alert]).to match(/Invalid mirror update request/)
        end
      end

      context 'with json format' do
        it 'processes an unsuccessful update' do
          do_put(project, { wrong: :params }, { format: :json })

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to eq('error' => 'Invalid mirror update request')
        end
      end
    end
  end

  describe '#ssh_host_keys', :use_clean_rails_memory_store_caching do
    let(:project) { create(:project) }
    let(:cache) { SshHostKey.new(project: project, url: "ssh://example.com:22") }

    before do
      sign_in(project.first_owner)
    end

    context 'invalid URLs' do
      %w[
        INVALID
        git@example.com:foo/bar.git
        ssh://git@example.com:foo/bar.git
        ssh://127.0.0.1/foo/bar.git
      ].each do |url|
        it "returns an error with a 400 response for URL #{url.inspect}" do
          do_get(project, url)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to eq('message' => 'Invalid URL')
        end
      end
    end

    context 'no data in cache' do
      it 'requests the cache to be filled and returns a 204 response' do
        expect(ExternalServiceReactiveCachingWorker).to receive(:perform_async).with(cache.class, cache.id).at_least(:once)

        do_get(project)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'error in the cache' do
      it 'returns the error with a 400 response' do
        stub_reactive_cache(cache, error: 'An error')

        do_get(project)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq('message' => 'An error')
      end
    end

    context 'data in the cache' do
      let(:ssh_key) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf' }
      let(:ssh_fp) { { type: 'ed25519', bits: 256, fingerprint: '2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16', fingerprint_sha256: 'SHA256:eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8', index: 0 } }

      it 'returns the data with a 200 response' do
        stub_reactive_cache(cache, known_hosts: ssh_key)

        do_get(project)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq('known_hosts' => ssh_key, 'fingerprints' => [ssh_fp.stringify_keys], 'host_keys_changed' => true)
      end
    end

    def do_get(project, url = 'ssh://example.com')
      get :ssh_host_keys, params: { namespace_id: project.namespace, project_id: project, ssh_url: url }
    end
  end

  def do_put(project, options, extra_attrs = {})
    attrs = extra_attrs.merge(namespace_id: project.namespace.to_param, project_id: project.to_param)
    attrs[:project] = options

    put :update, params: attrs
  end
end
