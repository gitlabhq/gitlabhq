# frozen_string_literal: true

describe QA::Scenario::Template do
  let(:feature) { spy('Runtime::Feature') }
  let(:release) { spy('Runtime::Release') }

  before do
    stub_const('QA::Runtime::Release', release)
    stub_const('QA::Runtime::Feature', feature)
    allow(QA::Specs::Runner).to receive(:perform)
    allow(QA::Runtime::Address).to receive(:valid?).and_return(true)
  end

  it 'allows a feature to be enabled' do
    subject.perform({ enable_feature: 'a-feature' })

    expect(feature).to have_received(:enable).with('a-feature')
  end

  it 'ensures an enabled feature is disabled afterwards' do
    allow(QA::Specs::Runner).to receive(:perform).and_raise('failed test')

    expect { subject.perform({ enable_feature: 'a-feature' }) }.to raise_error('failed test')

    expect(feature).to have_received(:enable).with('a-feature')
    expect(feature).to have_received(:disable).with('a-feature')
  end
end
