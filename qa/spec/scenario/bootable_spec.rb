# frozen_string_literal: true

RSpec.describe QA::Scenario::Bootable do
  subject do
    Class.new(QA::Scenario::Template)
      .include(described_class)
  end

  before do
    allow(subject).to receive(:options).and_return([])
    allow(QA::Runtime::Scenario).to receive(:attributes).and_return({})
  end

  it 'makes it possible to define the scenario attribute' do
    subject.class_eval do
      attribute :something, '--something SOMETHING', 'Some attribute'
      attribute :another, '--another ANOTHER', 'Some other attribute'
    end

    # If we run just this test from the command line it fails unless
    # we include the command line args that we use to select this test.
    expect(subject).to receive(:perform)
      .with({ something: 'test', another: 'other' })

    subject.launch!(%w[--another other --something test])
  end

  it 'does not require attributes to be defined' do
    expect(subject).to receive(:perform).with('some', 'argv')

    subject.launch!(%w[some argv])
  end
end
