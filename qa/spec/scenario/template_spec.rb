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
    stub_const('QA::Runtime::Scenario', scenario)
    stub_const('QA::Specs::Runner', runner)

    allow(QA::Runtime::Env).to receive(:knapsack?).and_return(false)
    allow(QA::Runtime::Env).to receive(:gitlab_url).and_return(gitlab_address_from_env)

    allow(QA::Runtime::Browser).to receive(:configure!)

    allow(scenario).to receive(:attributes).and_return({ gitlab_address: gitlab_address })
    allow(scenario).to receive(:define)

    QA::Support::GitlabAddress.instance_variable_set(:@initialized, false)
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
