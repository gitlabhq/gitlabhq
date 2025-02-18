# frozen_string_literal: true

RSpec.shared_examples 'a query processor' do
  describe '.transform' do
    it 'delegates to a new instance' do
      query = ActiveContext::Query.filter(foo: :bar)
      processor = instance_double(described_class)

      expect(described_class).to receive(:new).and_return(processor)
      expect(processor).to receive(:process).with(query)

      described_class.transform(query)
    end
  end

  describe '#process' do
    subject(:processor) { described_class.new }

    it 'requires implementation in subclass' do
      expect(processor).to respond_to(:process)
    end
  end

  describe 'error handling' do
    subject(:processor) { described_class.new }

    it 'raises ArgumentError for unsupported node types' do
      query = instance_double(ActiveContext::Query, type: :invalid)
      expect { processor.process(query) }.to raise_error(ArgumentError, /unsupported.*type/i)
    end
  end
end
