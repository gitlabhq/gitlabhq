# frozen_string_literal: true

module QA
  RSpec.describe Service::DockerRun::Npm do
    let(:volume_host_path) { '/tmp/npm-test' }
    let(:network) { 'test-network' }
    let(:host_name) { 'npm-host' }
    let(:gitlab_address_without_port) { 'http://gdk.test:3000' }
    let(:package_name) { '@my-scope/my-package' }
    let(:registry_scope) { 'my-scope' }
    let(:package_project_id) { 42 }
    let(:install_registry_url) { "#{gitlab_address_without_port}/api/v4/groups/7/-/packages/npm/" }
    let(:token) { 'test-token-123' }

    subject(:service) do
      described_class.new(
        volume_host_path,
        gitlab_address_without_port: gitlab_address_without_port,
        package_name: package_name,
        registry_scope: registry_scope,
        package_project_id: package_project_id,
        install_registry_url: install_registry_url,
        token: token
      )
    end

    before do
      allow(service).to receive_messages(shell: '', network: network, host_name: host_name)
      allow(Support::Retrier).to receive(:retry_until).and_yield
    end

    describe '#publish_and_install!' do
      it 'sets up container, publishes, installs, and cleans up' do
        service.publish_and_install!

        expect(service).to have_received(:shell).with(
          a_string_matching(%r{docker run -d --rm.*--network #{network}.*sleep 300})
        )
        expect(service).to have_received(:shell).with(
          a_string_matching(%r{docker cp #{Regexp.escape(volume_host_path)}/\..*:/home/node})
        )
        expect(service).to have_received(:shell).with(a_string_matching(/npm publish/), any_args)
        expect(service).to have_received(:shell).with(
          a_string_matching(/npm install #{Regexp.escape(package_name)}/)
        )
        expect(service).to have_received(:shell).with(a_string_matching(/docker stop/))
      end

      it 'stops the container even when publish fails' do
        allow(service).to receive(:shell).and_call_original
        allow(service).to receive(:shell).with(a_string_matching(/docker run/)).and_return('')
        allow(service).to receive(:shell).with(a_string_matching(/docker cp/)).and_return('')
        allow(service).to receive(:shell).with(a_string_matching(/npm publish/), any_args)
          .and_raise(StandardError, 'publish failed')
        allow(service).to receive(:shell).with(a_string_matching(/docker stop/)).and_return('')

        expect { service.publish_and_install! }.to raise_error(StandardError, 'publish failed')
        expect(service).to have_received(:shell).with(a_string_matching(/docker stop/))
      end

      it 'stops the container even when install fails' do
        allow(service).to receive(:shell).and_call_original
        allow(service).to receive(:shell).with(a_string_matching(/docker run/)).and_return('')
        allow(service).to receive(:shell).with(a_string_matching(/docker cp/)).and_return('')
        allow(service).to receive(:shell).with(a_string_matching(/npm publish/), any_args)
          .and_return('')
        allow(Support::Retrier).to receive(:retry_until)
          .and_raise(StandardError, 'install failed')
        allow(service).to receive(:shell).with(a_string_matching(/docker stop/)).and_return('')

        expect { service.publish_and_install! }.to raise_error(StandardError, 'install failed')
        expect(service).to have_received(:shell).with(a_string_matching(/docker stop/))
      end
    end

    describe 'setup_container' do
      before do
        service.publish_and_install!
      end

      it 'starts a sleep container on the correct network' do
        expect(service).to have_received(:shell).with(
          a_string_matching(
            %r{docker run -d --rm.*--network #{network}.*--hostname #{host_name}.*node:lts-alpine sh -c "sleep 300"}
          )
        )
      end

      it 'copies fixture files into the container' do
        expect(service).to have_received(:shell).with(
          a_string_matching(%r{docker cp #{Regexp.escape(volume_host_path)}/\..*:/home/node})
        )
      end
    end

    describe 'publish_package' do
      before do
        service.publish_and_install!
      end

      it 'passes the token via environment variable' do
        expect(service).to have_received(:shell).with(
          a_string_matching(/-e NPM_TOKEN=#{token}/),
          any_args
        )
      end

      it 'uses $NPM_TOKEN in .npmrc instead of the raw token' do
        expect(service).to have_received(:shell).with(
          a_string_matching(%r{_authToken=\$NPM_TOKEN}),
          any_args
        )
      end

      it 'masks the token in logs' do
        expect(service).to have_received(:shell).with(
          a_string_matching(/npm publish/),
          hash_including(mask_secrets: [token])
        )
      end

      it 'configures .npmrc with project-level auth token' do
        expect(service).to have_received(:shell).with(
          a_string_matching(
            %r{//gdk\.test:3000/api/v4/projects/#{package_project_id}/packages/npm/:_authToken=}
          ),
          any_args
        )
      end

      it 'configures .npmrc with install registry auth token' do
        expect(service).to have_received(:shell).with(
          a_string_matching(
            %r{//gdk\.test:3000/api/v4/groups/7/-/packages/npm/:_authToken=}
          ),
          any_args
        )
      end

      it 'configures the registry scope to the install registry URL' do
        expect(service).to have_received(:shell).with(
          a_string_matching(/@#{registry_scope}:registry=#{Regexp.escape(install_registry_url)}/),
          any_args
        )
      end

      it 'runs npm publish from the working directory' do
        expect(service).to have_received(:shell).with(
          a_string_matching(%r{cd /home/node && npm publish}),
          any_args
        )
      end
    end

    describe 'install_package' do
      before do
        service.publish_and_install!
      end

      it 'installs the package with retry logic' do
        expect(Support::Retrier).to have_received(:retry_until).with(
          hash_including(max_duration: 180, retry_on_exception: true, sleep_interval: 2)
        )
      end

      it 'runs npm install with the package name' do
        expect(service).to have_received(:shell).with(
          a_string_matching(/npm install #{Regexp.escape(package_name)}/)
        )
      end
    end

    context 'with instance-level install URL' do
      let(:install_registry_url) { "#{gitlab_address_without_port}/api/v4/packages/npm/" }

      before do
        service.publish_and_install!
      end

      it 'configures .npmrc with instance-level auth token' do
        expect(service).to have_received(:shell).with(
          a_string_matching(%r{//gdk\.test:3000/api/v4/packages/npm/:_authToken=}),
          any_args
        )
      end

      it 'configures the registry scope to the instance URL' do
        expect(service).to have_received(:shell).with(
          a_string_matching(/@#{registry_scope}:registry=#{Regexp.escape(install_registry_url)}/),
          any_args
        )
      end
    end

    context 'with project-level install URL' do
      let(:install_registry_url) do
        "#{gitlab_address_without_port}/api/v4/projects/#{package_project_id}/packages/npm/"
      end

      before do
        service.publish_and_install!
      end

      it 'configures .npmrc with project-level auth token for install' do
        expect(service).to have_received(:shell).with(
          a_string_matching(
            %r{//gdk\.test:3000/api/v4/projects/#{package_project_id}/packages/npm/:_authToken=}
          ),
          any_args
        )
      end

      it 'configures the registry scope to the project URL' do
        expect(service).to have_received(:shell).with(
          a_string_matching(/@#{registry_scope}:registry=#{Regexp.escape(install_registry_url)}/),
          any_args
        )
      end
    end

    context 'with token containing special characters' do
      let(:token) { "token'with;special&chars" }

      it 'does not embed the raw token in the shell command string' do
        service.publish_and_install!

        expect(service).to have_received(:shell).with(
          a_string_matching(/\$NPM_TOKEN/),
          any_args
        )
      end
    end
  end
end
