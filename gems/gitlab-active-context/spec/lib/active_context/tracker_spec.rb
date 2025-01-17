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
    context 'with single object' do
      it 'tracks references and returns count' do
        result = described_class.track!('test', collection: mock_collection)

        expect(result).to eq(1)
        expect(mock_collection.queue).to contain_exactly(['ref_test'])
      end
    end

    context 'with multiple objects' do
      it 'tracks references for all objects and returns total count' do
        result = described_class.track!('test1', 'test2', collection: mock_collection)

        expect(result).to eq(2)
        expect(mock_collection.queue).to contain_exactly(%w[ref_test1 ref_test2])
      end
    end

    context 'with nested arrays' do
      it 'flattens arrays and tracks all references' do
        result = described_class.track!(['test1', %w[test2 test3]], collection: mock_collection)

        expect(result).to eq(3)
        expect(mock_collection.queue).to contain_exactly(%w[ref_test1 ref_test2 ref_test3])
      end
    end

    context 'with empty input' do
      it 'returns zero and does not modify queue' do
        result = described_class.track!([], collection: mock_collection)

        expect(result).to eq(0)
        expect(mock_collection.queue).to be_empty
      end
    end

    context 'with custom queue' do
      it 'uses provided queue instead of collection queue' do
        result = described_class.track!('test', collection: mock_collection, queue: mock_queue)

        expect(result).to eq(1)
        expect(mock_queue).to contain_exactly(['ref_test'])
        expect(mock_collection.queue).to be_empty
      end
    end

    context 'when collection does not implement queue method' do
      let(:invalid_collection) do
        Class.new do
          include ActiveContext::Concerns::Collection

          def references
            ["ref"]
          end
        end
      end

      it 'raises NotImplementedError' do
        expect do
          described_class.track!('test', collection: invalid_collection)
        end.to raise_error(NotImplementedError)
      end
    end
  end

  describe '.collect_references' do
    it 'is a private method' do
      expect(described_class.private_methods).to include(:collect_references)
    end
  end
end
