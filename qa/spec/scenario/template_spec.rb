# frozen_string_literal: true

RSpec.describe QA::Scenario::Template do
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

  it 'allows a feature to be disabled' do
    allow(QA::Runtime::Feature).to receive(:enabled?)
                                     .with('another-feature').and_return(true)

    subject.perform({ disable_feature: 'another-feature' })

    expect(feature).to have_received(:disable).with('another-feature')
  end

  it 'does not disable a feature if already disabled' do
    allow(QA::Runtime::Feature).to receive(:enabled?)
                                     .with('another-feature').and_return(false)

    subject.perform({ disable_feature: 'another-feature' })

    expect(feature).not_to have_received(:disable).with('another-feature')
  end

  it 'ensures an enabled feature is disabled afterwards' do
    allow(QA::Specs::Runner).to receive(:perform).and_raise('failed test')

    expect { subject.perform({ enable_feature: 'a-feature' }) }.to raise_error('failed test')

    expect(feature).to have_received(:enable).with('a-feature')
    expect(feature).to have_received(:disable).with('a-feature')
  end

  it 'ensures a disabled feature is enabled afterwards' do
    allow(QA::Specs::Runner).to receive(:perform).and_raise('failed test')

    allow(QA::Runtime::Feature).to receive(:enabled?)
                                     .with('another-feature').and_return(true)

    expect { subject.perform({ disable_feature: 'another-feature' }) }.to raise_error('failed test')

    expect(feature).to have_received(:disable).with('another-feature')
    expect(feature).to have_received(:enable).with('another-feature')
  end

  it 'ensures a disabled feature is not enabled afterwards if it was disabled earlier' do
    allow(QA::Specs::Runner).to receive(:perform).and_raise('failed test')

    allow(QA::Runtime::Feature).to receive(:enabled?)
                                     .with('another-feature').and_return(false)

    expect { subject.perform({ disable_feature: 'another-feature' }) }.to raise_error('failed test')

    expect(feature).not_to have_received(:disable).with('another-feature')
    expect(feature).not_to have_received(:enable).with('another-feature')
  end
end
