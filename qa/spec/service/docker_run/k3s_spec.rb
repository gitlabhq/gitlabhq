# frozen_string_literal: true

module QA
  RSpec.describe Service::DockerRun::K3s do
    describe '#host_name' do
      context 'in CI' do
        let(:name) { 'k3s-12345' }
        let(:network) { 'thenet' }

        before do
          allow(Runtime::Env).to receive(:running_in_ci?).and_return(true)
          allow(subject).to receive(:network).and_return(network)
          subject.instance_variable_set(:@name, name)
        end

        it 'returns name.network' do
          expect(subject.host_name).to eq("#{name}.#{network}")
        end
      end

      context 'not in CI' do
        before do
          allow(Runtime::Env).to receive(:running_in_ci?).and_return(false)
        end

        it 'returns localhost if not running in a CI environment' do
          expect(subject.host_name).to eq('localhost')
        end
      end
    end
  end
end
