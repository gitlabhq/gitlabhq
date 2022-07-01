# frozen_string_literal: true

module QA
  RSpec.describe QA::Service::DockerRun::Mixins::ThirdPartyDocker do
    include QA::Support::Helpers::StubEnv

    let(:klass) do
      Class.new(Service::DockerRun::Base) do
        include Service::DockerRun::Mixins::ThirdPartyDocker

        def initialize(repo: Runtime::Env.third_party_docker_repository)
          @image = "#{repo}/some-image:latest"
        end
      end
    end

    let(:service) { klass.new }

    before do
      Service::DockerRun::Base.authenticated_registries.transform_values! { |_v| false }
    end

    context 'with environment set' do
      before do
        stub_env('QA_THIRD_PARTY_DOCKER_REGISTRY', 'registry.foobar.com')
        stub_env('QA_THIRD_PARTY_DOCKER_REPOSITORY', 'registry.foobar.com/some/path')
        stub_env('QA_THIRD_PARTY_DOCKER_USER', 'username')
        stub_env('QA_THIRD_PARTY_DOCKER_PASSWORD', 'secret')
      end

      it 'resolves the registry from the environment' do
        expect(service.third_party_registry).to eql('registry.foobar.com')
      end

      it 'sends a command to authenticate against the registry' do
        expect(service).to receive(:shell)
                             .with(
                               'docker login --username "username" --password "secret" registry.foobar.com',
                               mask_secrets: ['secret']
                             )
                             .and_return(nil)

        service.authenticate_third_party
      end
    end

    context 'without environment set' do
      before do
        stub_env('QA_THIRD_PARTY_DOCKER_REGISTRY', nil)
        stub_env('QA_THIRD_PARTY_DOCKER_USER', 'username')
        stub_env('QA_THIRD_PARTY_DOCKER_PASSWORD', 'secret')
      end

      it 'resolving the registry returns nil' do
        expect(service.third_party_registry).to be(nil)
      end

      it 'throws if environment is missing' do
        expect(service).not_to receive(:shell)

        expect { service.authenticate_third_party }.to raise_error do |err|
          expect(err.class).to be(Service::DockerRun::ThirdPartyValidationError)
          expect(err.message).to eql('Third party docker environment variable(s) are not set')
        end
      end
    end
  end
end
