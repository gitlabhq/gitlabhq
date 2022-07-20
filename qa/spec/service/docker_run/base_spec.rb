# frozen_string_literal: true

module QA
  RSpec.describe Service::DockerRun::Base do
    context 'when authenticating' do
      let(:instance_one) { Service::DockerRun::Base.new }
      let(:instance_two) { Service::DockerRun::Base.new }

      before do
        # reset singleton registry state
        Service::DockerRun::Base.authenticated_registries.transform_values! { |_v| false }
      end

      it 'caches the the registry' do
        expect(instance_one).to receive(:shell).once.and_return(nil)
        expect(instance_two).not_to receive(:shell)

        instance_one.login('registry.foobar.com', user: 'foobar', password: 'secret')
        instance_two.login('registry.foobar.com', user: 'foobar', password: 'secret')
      end

      it 'forces authentication if the registry is cached' do
        expect(instance_one).to receive(:shell).once.and_return(nil)
        expect(instance_two).to receive(:shell).once.and_return(nil)

        instance_one.login('registry.foobar.com', user: 'foobar', password: 'secret')
        instance_two.login('registry.foobar.com', user: 'foobar', password: 'secret', force: true)
      end
    end
  end
end
