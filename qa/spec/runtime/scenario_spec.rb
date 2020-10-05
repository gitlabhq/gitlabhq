# frozen_string_literal: true

RSpec.describe QA::Runtime::Scenario do
  subject do
    Module.new.extend(described_class)
  end

  it 'makes it possible to define global scenario attributes' do
    subject.define(:my_attribute, 'some-value')
    subject.define(:another_attribute, 'another-value')

    expect(subject.my_attribute).to eq 'some-value'
    expect(subject.another_attribute).to eq 'another-value'
    expect(subject.attributes)
      .to eq(my_attribute: 'some-value', another_attribute: 'another-value')
  end

  it 'replaces an existing attribute' do
    subject.define(:my_attribute, 'some-value')
    subject.define(:my_attribute, 'another-value')

    expect(subject.my_attribute).to eq 'another-value'
    expect(subject.attributes).to eq(my_attribute: 'another-value')
  end

  it 'raises error when attribute is not known' do
    expect { subject.invalid_accessor }
      .to raise_error ArgumentError, /invalid_accessor/
  end

  it 'raises error when attribute is empty' do
    subject.define(:empty_attribute, '')

    expect { subject.empty_attribute }
      .to raise_error ArgumentError, /empty_attribute/
  end
end
