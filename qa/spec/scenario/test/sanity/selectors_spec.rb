# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Sanity::Selectors do
  let(:validator) { spy('validator') }

  before do
    stub_const('QA::Page::Validator', validator)

    allow(QA::Runtime::Logger).to receive(:warn)
    allow(QA::Runtime::Logger).to receive(:info)
  end

  context 'when there are errors detected' do
    let(:error) { 'some error' }

    before do
      allow(validator).to receive(:errors).and_return([error])
    end

    it 'outputs information about errors', :aggregate_failures do
      described_class.perform

      expect(QA::Runtime::Logger).to have_received(:warn)
        .with(/GitLab QA sanity selectors validation test detected problems/)

      expect(QA::Runtime::Logger).to have_received(:warn)
        .with(/#{error}/)
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
