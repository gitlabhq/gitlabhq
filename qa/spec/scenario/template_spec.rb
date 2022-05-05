# frozen_string_literal: true

RSpec.describe QA::Scenario::Template do
  let(:release) { spy('QA::Runtime::Release') } # rubocop:disable RSpec/VerifiedDoubles
  let(:feature) { class_spy('QA::Runtime::Feature') }
  let(:scenario) { class_spy('QA::Runtime::Scenario') }
  let(:runner) { class_spy('QA::Specs::Runner') }

  let(:gitlab_address) { 'https://gitlab.com/' }
  let(:gitlab_address_from_env) { 'https://staging.gitlab.com/' }

  before do
    stub_const('QA::Runtime::Release', release)
    stub_const('QA::Runtime::Feature', feature)
    stub_const('QA::Runtime::Scenario', scenario)
    stub_const('QA::Specs::Runner', runner)

    allow(QA::Runtime::Env).to receive(:knapsack?).and_return(false)
    allow(QA::Runtime::Env).to receive(:gitlab_url).and_return(gitlab_address_from_env)

    allow(QA::Runtime::Browser).to receive(:configure!)

    allow(scenario).to receive(:attributes).and_return({ gitlab_address: gitlab_address })
    allow(scenario).to receive(:define)

    QA::Support::GitlabAddress.instance_variable_set(:@initialized, false)
  end

  it 'allows a feature to be enabled' do
    subject.perform({ gitlab_address: gitlab_address, enable_feature: 'a-feature' })

    expect(feature).to have_received(:enable).with('a-feature')
    expect(feature).to have_received(:disable).with('a-feature')
  end

  it 'allows a feature to be disabled' do
    allow(QA::Runtime::Feature).to receive(:enabled?).with('another-feature').and_return(true)

    subject.perform({ gitlab_address: gitlab_address, disable_feature: 'another-feature' })

    expect(feature).to have_received(:disable).with('another-feature')
    expect(feature).to have_received(:enable).with('another-feature')
  end

  it 'does not disable a feature if already disabled' do
    allow(QA::Runtime::Feature).to receive(:enabled?).with('another-feature').and_return(false)

    subject.perform({ gitlab_address: gitlab_address, disable_feature: 'another-feature' })

    expect(feature).not_to have_received(:disable).with('another-feature')
  end

  it 'ensures an enabled feature is disabled afterwards' do
    allow(QA::Specs::Runner).to receive(:perform).and_raise('failed test')

    expect { subject.perform({ gitlab_address: gitlab_address, enable_feature: 'a-feature' }) }
      .to raise_error('failed test')

    expect(feature).to have_received(:enable).with('a-feature')
    expect(feature).to have_received(:disable).with('a-feature')
  end

  it 'ensures a disabled feature is enabled afterwards' do
    allow(QA::Specs::Runner).to receive(:perform).and_raise('failed test')
    allow(QA::Runtime::Feature).to receive(:enabled?).with('another-feature').and_return(true)

    expect { subject.perform({ gitlab_address: gitlab_address, disable_feature: 'another-feature' }) }
      .to raise_error('failed test')

    expect(feature).to have_received(:disable).with('another-feature')
    expect(feature).to have_received(:enable).with('another-feature')
  end

  it 'ensures a disabled feature is not enabled afterwards if it was disabled earlier' do
    allow(QA::Specs::Runner).to receive(:perform).and_raise('failed test')
    allow(QA::Runtime::Feature).to receive(:enabled?).with('another-feature').and_return(false)

    expect { subject.perform({ gitlab_address: gitlab_address, disable_feature: 'another-feature' }) }
      .to raise_error('failed test')

    expect(feature).not_to have_received(:disable).with('another-feature')
    expect(feature).not_to have_received(:enable).with('another-feature')
  end

  it 'defines gitlab address from positional argument' do
    allow(scenario).to receive(:attributes).and_return({})

    subject.perform({}, gitlab_address)

    expect(scenario).to have_received(:define).with(:gitlab_address, gitlab_address)
    expect(scenario).to have_received(:define).with(:about_address, 'https://about.gitlab.com/')
  end

  it "defaults to gitlab address from env" do
    allow(scenario).to receive(:attributes).and_return({})

    subject.perform({})

    expect(scenario).to have_received(:define).with(:gitlab_address, gitlab_address_from_env)
  end

  it 'defines klass attribute' do
    subject.perform({ gitlab_address: gitlab_address })

    expect(scenario).to have_received(:define).with(:klass, 'QA::Scenario::Template')
  end
end
