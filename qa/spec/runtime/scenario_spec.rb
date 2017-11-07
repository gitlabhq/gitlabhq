describe QA::Runtime::Scenario do
  subject do
    Module.new.extend(described_class)
  end

  it 'makes it possible to define global scenario arguments' do
    subject.define([1, :a, 's']) do
      attributes :some_number, :some_symbol, :some_string
    end

    expect(subject.some_number).to eq 1
    expect(subject.some_symbol).to eq :a
    expect(subject.some_string).to eq 's'
  end

  it 'raises error when attribute is not known' do
    expect { subject.invalid_accessor }
      .to raise_error ArgumentError, /invalid_accessor/
  end

  it 'raises error when attribute is empty' do
    subject.define([nil, '']) do
      attributes :nil_attribute, :empty_attribute
    end

    expect { subject.nil_attribute }
      .to raise_error ArgumentError, /nil_attribute/
    expect { subject.empty_attribute }
      .to raise_error ArgumentError, /empty_attribute/
  end
end
