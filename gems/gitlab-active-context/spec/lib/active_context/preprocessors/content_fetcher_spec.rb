# frozen_string_literal: true

RSpec.describe ActiveContext::Preprocessors::ContentFetcher do
  let(:reference_class) do
    Class.new(Test::References::Mock) do
      include ::ActiveContext::Preprocessors::ContentFetcher

      add_preprocessor :fetch_content do |refs|
        fetch_content(refs: refs, query: '*', collection: 'mock_collection')
      end
    end
  end

  let(:reference_1) { reference_class.new(collection_id: collection_id, routing: partition, args: 'id1') }
  let(:reference_2) { reference_class.new(collection_id: collection_id, routing: partition, args: 'id2') }

  let(:mock_adapter) { double }
  let(:mock_collection) { double(name: collection_name, partition_for: partition, include_ref_fields: true) }
  let(:mock_connection) { double(id: connection_id) }

  let(:query) { '*' }
  let(:connection_id) { 3 }
  let(:partition) { 2 }
  let(:collection_id) { 1 }
  let(:collection_name) { 'mock_collection' }

  let(:search_results) do
    [
      { 'id' => 'id1', 'content' => 'Content for document 1' },
      { 'id' => 'id2', 'content' => 'Content for document 2' }
    ]
  end

  subject(:process_refs) { ActiveContext::Reference.preprocess_references([reference_1, reference_2]) }

  before do
    allow(ActiveContext).to receive(:adapter).and_return(mock_adapter)
    allow(mock_adapter).to receive(:search).and_return(search_results)
    allow(ActiveContext::CollectionCache).to receive(:fetch).and_return(mock_collection)
    allow(ActiveContext::Logger).to receive(:skippable_exception).and_return(nil)
  end

  describe '.fetch_content' do
    context 'when content is found for all references' do
      it 'fetches content and adds it to reference documents' do
        process_refs

        expect(reference_1.documents).to include({ content: 'Content for document 1' })
        expect(reference_2.documents).to include({ content: 'Content for document 2' })
      end

      it 'calls search with the correct parameters' do
        expect(mock_adapter).to receive(:search).with(
          user: nil,
          collection: collection_name,
          query: query,
          source_fields: %w[id content]
        )

        process_refs
      end

      it 'returns the references' do
        result = process_refs

        expect(result[:successful]).to eq([reference_1, reference_2])
        expect(result[:failed]).to be_empty
      end
    end

    context 'when content is not found for some references' do
      let(:search_results) do
        [
          { 'id' => 'id1', 'content' => 'Content for document 1' }
        ]
      end

      it 'does not add the ref to the failed refs result', :aggregate_failures do
        expect(ActiveContext::Logger).to receive(:retryable_exception) do |e, kwargs|
          expect(e).to be_a(ActiveContext::Preprocessors::ContentFetcher::ContentNotFoundError)
          expect(e.message).to eq("content not found for chunk with id: id2")
          expect(kwargs[:class]).to eq("Class")
          expect(kwargs[:reference]).to match(/id2/)
          expect(kwargs[:reference_id]).to eq("id2")
        end

        result = process_refs

        expect(result[:successful]).to eq([reference_1])
        expect(result[:failed]).to eq([reference_2])
      end
    end

    context 'when skip_missing_content is true' do
      let(:reference_class) do
        Class.new(Test::References::Mock) do
          include ::ActiveContext::Preprocessors::ContentFetcher

          add_preprocessor :fetch_content do |refs, skip_missing_content: false, **|
            fetch_content(refs: refs, query: '*', collection: 'mock_collection',
              skip_missing_content: skip_missing_content)
          end
        end
      end

      let(:search_results) do
        [
          { 'id' => 'id1', 'content' => 'Content for document 1' }
        ]
      end

      subject(:process_refs) do
        ActiveContext::Reference.preprocess_references(
          [reference_1, reference_2],
          skip_missing_content: true
        )
      end

      it 'skips missing refs instead of failing them', :aggregate_failures do
        expect(ActiveContext::Logger).to receive(:skippable_exception) do |e, kwargs|
          expect(e).to be_a(ActiveContext::Preprocessors::ContentFetcher::ContentNotFoundError)
          expect(kwargs[:reference_id]).to eq("id2")
        end

        result = process_refs

        expect(result[:successful]).to eq([reference_1])
        expect(result[:failed]).to be_empty
      end
    end
  end
end
