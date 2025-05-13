# frozen_string_literal: true

RSpec.shared_examples 'a query processor' do
  let(:processor_class) { described_class }

  describe '.transform' do
    it 'delegates to a new instance' do
      query = ActiveContext::Query.filter(foo: :bar)
      processor = instance_double(processor_class)

      expect(processor_class).to receive(:new).with(collection: collection, user: user).and_return(processor)
      expect(processor).to receive(:process).with(query)

      processor_class.transform(collection: collection, node: query, user: user)
    end
  end

  describe '#process' do
    subject(:processor) { processor_class.new(collection: collection, user: user) }

    it 'requires implementation in subclass' do
      expect(processor).to respond_to(:process)
    end
  end

  describe 'error handling' do
    subject(:processor) { processor_class.new(collection: collection, user: user) }

    it 'raises ArgumentError for unsupported node types' do
      query = instance_double(ActiveContext::Query, type: :invalid)
      expect { processor.process(query) }.to raise_error(ArgumentError, /unsupported.*type/i)
    end
  end
end
