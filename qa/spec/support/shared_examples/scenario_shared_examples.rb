# frozen_string_literal: true

module QA
  RSpec.shared_examples 'a QA scenario class' do
    let(:attributes) { spy('Runtime::Scenario') }
    let(:runner) { spy('Specs::Runner') }
    let(:release) { spy('Runtime::Release') }
    let(:feature) { spy('Runtime::Feature') }

    let(:args) { { gitlab_address: 'http://gitlab_address' } }
    let(:named_options) { %w[--address http://gitlab_address] }
    let(:tags) { [] }
    let(:options) { %w[path1 path2] }

    before do
      stub_const('QA::Specs::Runner', runner)
      stub_const('QA::Runtime::Release', release)
      stub_const('QA::Runtime::Scenario', attributes)
      stub_const('QA::Runtime::Feature', feature)

      allow(attributes).to receive(:gitlab_address).and_return(args[:gitlab_address])
      allow(runner).to receive(:perform).and_yield(runner)
      allow(QA::Runtime::Address).to receive(:valid?).and_return(true)
    end

    it 'responds to perform' do
      expect(subject).to respond_to(:perform)
    end

    it 'sets an address of the subject' do
      subject.perform(args)

      expect(attributes).to have_received(:define).with(:gitlab_address, 'http://gitlab_address').at_least(:once)
    end

    it 'performs before hooks only once' do
      subject.perform(args)

      expect(release).to have_received(:perform_before_hooks).once
    end

    it 'sets tags on runner' do
      subject.perform(args)

      expect(runner).to have_received(:tags=).with(tags)
    end

    context 'specifying RSpec options' do
      it 'sets options on runner' do
        subject.perform(args, *options)

        expect(runner).to have_received(:options=).with(options)
      end
    end

    context 'with named command-line options' do
      it 'converts options to attributes' do
        described_class.launch!(named_options)

        args do |k, v|
          expect(attributes).to have_received(:define).with(k, v)
        end
      end

      it 'raises an error if the option is invalid' do
        expect { described_class.launch!(['--foo']) }.to raise_error(OptionParser::InvalidOption)
      end

      it 'passes on options after --' do
        expect(described_class).to receive(:perform).with(attributes, *%w[--tag quarantine])

        described_class.launch!(named_options.push(*%w[-- --tag quarantine]))
      end
    end
  end
end
