describe QA::Scenario::Entrypoint do
  subject do
    Class.new(QA::Scenario::Entrypoint) do
      tags :rspec
    end
  end

  context '#perform' do
    let(:config) { spy('Specs::Config') }
    let(:release) { spy('Runtime::Release') }
    let(:runner) { spy('Specs::Runner') }

    before do
      allow(config).to receive(:perform) { |&block| block.call config }
      allow(runner).to receive(:perform) { |&block| block.call runner }

      stub_const('QA::Specs::Config', config)
      stub_const('QA::Runtime::Release', release)
      stub_const('QA::Specs::Runner', runner)
    end

    it 'should set address' do
      subject.perform("hello")

      expect(config).to have_received(:address=).with("hello")
    end

    context 'no paths' do
      it 'should call runner with default arguments' do
        subject.perform("test")

        expect(runner).to have_received(:rspec)
          .with(hash_including(files: 'qa/specs/features'))
      end
    end

    context 'specifying paths' do
      it 'should call runner with paths' do
        subject.perform('test', 'path1', 'path2')

        expect(runner).to have_received(:rspec)
          .with(hash_including(files: %w(path1 path2)))
      end
    end
  end
end
