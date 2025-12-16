# frozen_string_literal: true

RSpec.describe ActiveContext::Databases::Concerns::Adapter do
  # Create a test class that includes the adapter module
  let(:test_class) do
    Class.new do
      include ActiveContext::Databases::Concerns::Adapter

      def client_klass
        @client_klass ||= Struct.new(:options) do
          def new(options)
            self.class.new(options)
          end
        end
      end

      def indexer_klass
        @indexer_klass ||= Struct.new(:options, :client) do
          def new(options, client)
            self.class.new(options, client)
          end
        end
      end

      def executor_klass
        @executor_klass ||= Struct.new(:adapter) do
          def new(adapter)
            self.class.new(adapter)
          end
        end
      end
    end
  end

  let(:connection) { double('Connection') }
  let(:options) { { 'host' => 'localhost' } }

  subject(:adapter) { test_class.new(connection, options: options) }

  describe '#initialize' do
    it 'sets instance variables correctly' do
      expect(adapter.connection).to eq(connection)
      expect(adapter.options).to eq(options.symbolize_keys)
      expect(adapter.prefix).to eq('gitlab_active_context')
      expect(adapter.client).to be_a(Struct)
      expect(adapter.indexer).to be_a(Struct)
      expect(adapter.executor).to be_a(Struct)
    end

    context 'with custom prefix' do
      let(:options) { { host: 'localhost', prefix: 'custom_prefix' } }

      it 'sets the custom prefix' do
        expect(adapter.prefix).to eq('custom_prefix')
      end
    end
  end

  describe '#client_klass' do
    it 'is required to be implemented in subclasses' do
      # Create class to test just this method without initialize getting in the way
      test_class = Class.new do
        include ActiveContext::Databases::Concerns::Adapter

        # Override initialize so it doesn't try to call the methods we're testing
        def initialize; end

        # Don't implement other required methods
        def indexer_klass; end
        def executor_klass; end
      end

      adapter = test_class.new
      expect { adapter.client_klass }.to raise_error(NotImplementedError)
    end
  end

  describe '#indexer_klass' do
    it 'is required to be implemented in subclasses' do
      # Create class to test just this method without initialize getting in the way
      test_class = Class.new do
        include ActiveContext::Databases::Concerns::Adapter

        # Override initialize so it doesn't try to call the methods we're testing
        def initialize; end

        # Don't implement other required methods
        def client_klass; end
        def executor_klass; end
      end

      adapter = test_class.new
      expect { adapter.indexer_klass }.to raise_error(NotImplementedError)
    end
  end

  describe '#executor_klass' do
    it 'is required to be implemented in subclasses' do
      # Create class to test just this method without initialize getting in the way
      test_class = Class.new do
        include ActiveContext::Databases::Concerns::Adapter

        # Override initialize so it doesn't try to call the methods we're testing
        def initialize; end

        # Don't implement other required methods
        def client_klass; end
        def indexer_klass; end
      end

      adapter = test_class.new
      expect { adapter.executor_klass }.to raise_error(NotImplementedError)
    end
  end

  describe '#full_collection_name' do
    it 'joins prefix and name with separator' do
      expect(adapter.full_collection_name('test_collection')).to eq('gitlab_active_context_test_collection')
    end

    context 'with custom prefix' do
      let(:options) { { host: 'localhost', prefix: 'custom_prefix' } }

      it 'uses the custom prefix' do
        expect(adapter.full_collection_name('test_collection')).to eq('custom_prefix_test_collection')
      end
    end

    context 'when name already includes prefix' do
      it 'still adds the prefix' do
        expect(adapter.full_collection_name('gitlab_active_context_collection'))
          .to eq('gitlab_active_context_gitlab_active_context_collection')
      end
    end
  end

  describe '#separator' do
    it 'returns the default separator' do
      expect(adapter.separator).to eq('_')
    end
  end

  describe 'delegated methods' do
    let(:client) { double('Client') }
    let(:indexer) { double('Indexer') }

    before do
      allow(adapter).to receive_messages(client: client, indexer: indexer)
    end

    it 'delegates search to client' do
      query = double('Query')
      expect(client).to receive(:search).with(query)
      adapter.search(query)
    end

    it 'delegates all_refs to indexer' do
      expect(indexer).to receive(:all_refs)
      adapter.all_refs
    end

    it 'delegates add_ref to indexer' do
      ref = double('Reference')
      expect(indexer).to receive(:add_ref).with(ref)
      adapter.add_ref(ref)
    end

    it 'delegates empty? to indexer' do
      expect(indexer).to receive(:empty?)
      adapter.empty?
    end

    it 'delegates bulk to indexer' do
      operations = double('Operations')
      expect(indexer).to receive(:bulk).with(operations)
      adapter.bulk(operations)
    end

    it 'delegates process_bulk_errors to indexer' do
      errors = double('Errors')
      expect(indexer).to receive(:process_bulk_errors).with(errors)
      adapter.process_bulk_errors(errors)
    end

    it 'delegates reset to indexer' do
      expect(indexer).to receive(:reset)
      adapter.reset
    end
  end
end
