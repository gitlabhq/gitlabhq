# frozen_string_literal: true

RSpec.describe ActiveContext::Tracker do
  let(:mock_collection) do
    Class.new do
      include ActiveContext::Concerns::Collection

      def self.queue
        @queue ||= []
      end

      def references
        ["ref_#{object}"]
      end
    end
  end

  let(:mock_queue) { [] }

  describe '.track!' do
    let(:mock_collection) { double('Collection') }
    let(:mock_queue) { [] }

    before do
      allow(mock_collection).to receive(:queue).and_return(mock_queue)
    end

    it 'tracks a string as-is' do
      expect(described_class.track!('test_string', collection: mock_collection)).to eq(1)
      expect(mock_queue).to contain_exactly(['test_string'])
    end

    it 'serializes ActiveContext::Reference objects' do
      reference_class = Class.new(ActiveContext::Reference) do
        def serialize
          'serialized_reference'
        end
      end
      reference = reference_class.new

      expect(described_class.track!(reference, collection: mock_collection)).to eq(1)
      expect(mock_queue).to contain_exactly(['serialized_reference'])
    end

    it 'uses collection.references for other objects' do
      obj = double('SomeObject')
      collection_instance = instance_double('CollectionInstance')
      references = [instance_double(ActiveContext::Reference), instance_double(ActiveContext::Reference)]

      allow(mock_collection).to receive(:new).with(obj).and_return(collection_instance)
      allow(collection_instance).to receive(:references).and_return(references)

      expect(described_class.track!(obj, collection: mock_collection)).to eq(2)
      expect(mock_queue).to contain_exactly(references)
    end
  end

  describe '.collect_references' do
    it 'is a private method' do
      expect(described_class.private_methods).to include(:collect_references)
    end
  end
end
