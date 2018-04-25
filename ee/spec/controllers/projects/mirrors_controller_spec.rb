require 'spec_helper'

describe Projects::MirrorsController do
  include ReactiveCachingHelpers

  describe 'setting up a remote mirror' do
    set(:project) { create(:project, :repository) }
    let(:url) { 'http://foo.com' }

    context 'when the current project is a mirror' do
      let(:project) { create(:project, :repository, :mirror) }

      before do
        sign_in(project.owner)
      end

      it 'allows to create a remote mirror' do
        expect_any_instance_of(EE::Project).to receive(:force_import_job!)

        expect do
          do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => url } })
        end.to change { RemoteMirror.count }.to(1)
      end

      context 'when remote mirror has the same URL' do
        it 'does not allow to create the remote mirror' do
          expect do
            do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => project.import_url } })
          end.not_to change { RemoteMirror.count }
        end

        context 'with disabled local mirror' do
          it 'allows to create a remote mirror' do
            expect do
              do_put(project, mirror: 0, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => project.import_url } })
            end.to change { RemoteMirror.count }.to(1)
          end
        end
      end
    end

    context 'when the current project has a remote mirror' do
      let(:remote_mirror) { project.remote_mirrors.create!(enabled: 1, url: 'http://local.dev') }

      before do
        sign_in(project.owner)
      end

      context 'when trying to create a mirror with the same URL' do
        it 'should not setup the mirror' do
          do_put(project, mirror: true, import_url: remote_mirror.url)

          expect(project.reload.mirror).to be_falsey
          expect(project.reload.import_url).to be_blank
        end
      end

      context 'when trying to create a mirror with a different URL' do
        it 'should setup the mirror' do
          expect_any_instance_of(EE::Project).to receive(:force_import_job!)

          do_put(project, mirror: true, mirror_user_id: project.owner.id, import_url: 'http://local.dev')

          expect(project.reload.mirror).to eq(true)
          expect(project.reload.import_url).to eq('http://local.dev')
        end

        context 'mirror user is not the current user' do
          it 'should only assign the current user' do
            expect_any_instance_of(EE::Project).to receive(:force_import_job!)

            new_user = create(:user)
            project.add_master(new_user)

            do_put(project, mirror: true, mirror_user_id: new_user.id, import_url: 'http://local.dev')

            expect(project.reload.mirror).to eq(true)
            expect(project.reload.mirror_user.id).to eq(project.owner.id)
          end
        end
      end
    end
  end

  describe 'setting up a mirror' do
    let(:url) { 'http://foo.com' }
    let(:project) { create(:project, :repository) }

    context 'when mirrors are disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      context 'when user is admin' do
        let(:admin) { create(:user, :admin) }

        it 'creates a new mirror' do
          sign_in(admin)
          expect_any_instance_of(EE::Project).to receive(:force_import_job!)

          expect do
            do_put(project, mirror: true, mirror_user_id: admin.id, import_url: url)
          end.to change { Project.mirror.count }.to(1)
        end
      end

      context 'when user is not an admin' do
        it 'does not create a new mirror' do
          sign_in(project.owner)

          expect do
            do_put(project, mirror: true, mirror_user_id: project.owner.id, import_url: url)
          end.not_to change { Project.mirror.count }
        end
      end
    end

    context 'when mirrors are enabled' do
      before do
        sign_in(project.owner)
      end

      context 'when project does not have a mirror' do
        it 'allows to create a mirror' do
          expect_any_instance_of(EE::Project).to receive(:force_import_job!)

          expect do
            do_put(project, mirror: true, mirror_user_id: project.owner.id, import_url: url)
          end.to change { Project.mirror.count }.to(1)
        end
      end

      context 'when project has a mirror' do
        let(:project) { create(:project, :mirror, :import_finished) }

        it 'is able to disable the mirror' do
          expect { do_put(project, mirror: false) }.to change { Project.mirror.count }.to(0)
        end
      end
    end
  end

  describe 'forcing an update on a pull mirror' do
    it 'forces update' do
      project = create(:project, :mirror)
      sign_in(project.owner)

      expect_any_instance_of(EE::Project).to receive(:force_import_job!)

      put :update_now, { namespace_id: project.namespace.to_param, project_id: project.to_param }
    end
  end

  describe '#update' do
    let(:project) { create(:project, :repository, :mirror, :remote_mirror) }
    let(:attributes) { { project: { mirror_user_id: project.owner.id, mirror_trigger_builds: 0 }, namespace_id: project.namespace.to_param, project_id: project.to_param } }

    before do
      sign_in(project.owner)
    end

    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    context 'JSON' do
      it 'processes a successful update' do
        do_put(project, { import_url: 'https://updated.example.com' }, format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['import_url']).to eq('https://updated.example.com')
      end

      it 'processes an unsuccessful update' do
        do_put(project, { import_url: 'ftp://invalid.invalid' }, format: :json)

        expect(response).to have_gitlab_http_status(422)
        expect(json_response['import_url'].first).to match /valid URL/
      end

      it "preserves the import_data object when the ID isn't in the request" do
        import_data_id = project.import_data.id

        do_put(project, { import_data_attributes: { password: 'update' } }, format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(project.import_data(true).id).to eq(import_data_id)
      end

      it 'sets ssh_known_hosts_verified_at and verified_by when the update sets known hosts' do
        do_put(project, { import_data_attributes: { ssh_known_hosts: 'update' } }, format: :json)

        expect(response).to have_gitlab_http_status(200)

        import_data = project.import_data(true)
        expect(import_data.ssh_known_hosts_verified_at).to be_within(1.minute).of(Time.now)
        expect(import_data.ssh_known_hosts_verified_by).to eq(project.owner)
      end

      it 'unsets ssh_known_hosts_verified_at and verified_by when the update unsets known hosts' do
        project.import_data.update!(ssh_known_hosts: 'foo')

        do_put(project, { import_data_attributes: { ssh_known_hosts: '' } }, format: :json)

        expect(response).to have_gitlab_http_status(200)

        import_data = project.import_data(true)
        expect(import_data.ssh_known_hosts_verified_at).to be_nil
        expect(import_data.ssh_known_hosts_verified_by).to be_nil
      end

      it 'only allows the current user to be the mirror user' do
        mirror_user = project.mirror_user

        other_user = create(:user)
        project.add_master(other_user)

        do_put(project, { mirror_user_id: other_user.id }, format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(project.mirror_user(true)).to eq(mirror_user)
      end
    end

    context 'with a valid URL for a pull' do
      it 'processes a successful update' do
        do_put(project, username_only_import_url: "https://updated.example.com")

        expect(response).to redirect_to(project_settings_repository_path(project))
        expect(flash[:notice]).to match(/successfully updated/)
      end
    end

    context 'with a invalid URL for a pull' do
      it 'processes an unsuccessful update' do
        do_put(project, username_only_import_url: "ftp://invalid.invalid'")

        expect(response).to redirect_to(project_settings_repository_path(project))
        expect(flash[:alert]).to match(/must be a valid URL/)
      end
    end
  end

  describe '#ssh_host_keys', :use_clean_rails_memory_store_caching do
    let(:project) { create(:project) }
    let(:cache) { SshHostKey.new(project: project, url: "ssh://example.com:22") }

    before do
      sign_in(project.owner)
    end

    context 'invalid URLs' do
      where(url: %w[INVALID git@example.com:foo/bar.git ssh://git@example.com:foo/bar.git])

      with_them do
        it 'returns an error with a 400 response' do
          do_get(project, url)

          expect(response).to have_gitlab_http_status(400)
          expect(json_response).to eq('message' => 'Invalid URL')
        end
      end
    end

    context 'no data in cache' do
      it 'requests the cache to be filled and returns a 204 response' do
        expect(ReactiveCachingWorker).to receive(:perform_async).with(cache.class, cache.id).at_least(:once)

        do_get(project)

        expect(response).to have_gitlab_http_status(204)
      end
    end

    context 'error in the cache' do
      it 'returns the error with a 400 response' do
        stub_reactive_cache(cache, error: 'An error')

        do_get(project)

        expect(response).to have_gitlab_http_status(400)
        expect(json_response).to eq('message' => 'An error')
      end
    end

    context 'data in the cache' do
      let(:ssh_key) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf' }
      let(:ssh_fp) { { type: 'ed25519', bits: 256, fingerprint: '2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16', index: 0 } }

      it 'returns the data with a 200 response' do
        stub_reactive_cache(cache, known_hosts: ssh_key)

        do_get(project)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to eq('known_hosts' => ssh_key, 'fingerprints' => [ssh_fp.stringify_keys], 'changes_project_import_data' => true)
      end
    end

    def do_get(project, url = 'ssh://example.com')
      get :ssh_host_keys, namespace_id: project.namespace, project_id: project, ssh_url: url
    end
  end

  def do_put(project, options, extra_attrs = {})
    attrs = extra_attrs.merge(namespace_id: project.namespace.to_param, project_id: project.to_param)
    attrs[:project] = options

    put :update, attrs
  end
end
