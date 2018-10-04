# frozen_string_literal: true

shared_examples 'a QA scenario class' do
  let(:attributes) { spy('Runtime::Scenario') }
  let(:release) { spy('Runtime::Release') }
  let(:runner) { spy('Specs::Runner') }

  let(:args) { ['gitlab_address'] }
  let(:tags) { [] }
  let(:options) { %w[path1 path2] }

  before do
    stub_const('QA::Runtime::Release', release)
    stub_const('QA::Runtime::Scenario', attributes)
    stub_const('QA::Specs::Runner', runner)

    allow(runner).to receive(:perform).and_yield(runner)
  end

  it 'responds to perform' do
    expect(subject).to respond_to(:perform)
  end

  it 'sets an address of the subject' do
    subject.perform(*args)

    expect(attributes).to have_received(:define).with(:gitlab_address, 'gitlab_address')
  end

  it 'performs before hooks' do
    subject.perform(*args)

    expect(release).to have_received(:perform_before_hooks)
  end

  it 'sets tags on runner' do
    subject.perform(*args)

    expect(runner).to have_received(:tags=).with(tags)
  end

  context 'specifying RSpec options' do
    it 'sets options on runner' do
      subject.perform(*args, *options)

      expect(runner).to have_received(:options=).with(options)
    end
  end
end
