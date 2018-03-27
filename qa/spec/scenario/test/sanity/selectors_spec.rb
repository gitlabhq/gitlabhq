describe QA::Scenario::Test::Sanity::Selectors do
  let(:validator) { spy('validator') }

  before do
    stub_const('QA::Page::Validator', validator)
  end

  context 'when there are errors detected' do
    before do
      allow(validator).to receive(:errors).and_return(['some error'])
    end

    it 'outputs information about errors' do
      expect { described_class.perform }
        .to output(/some error/).to_stderr

      expect { described_class.perform }
        .to output(/electors validation test detected problems/)
        .to_stderr
    end
  end

  context 'when there are no errors detected' do
    before do
      allow(validator).to receive(:errors).and_return([])
    end

    it 'processes pages module' do
      described_class.perform

      expect(validator).to have_received(:new).with(QA::Page)
    end

    it 'triggers validation' do
      described_class.perform

      expect(validator).to have_received(:validate!).at_least(:once)
    end
  end
end
