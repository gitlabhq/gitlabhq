# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module Adapter
        attr_reader :options, :client, :indexer

        delegate :search, to: :client
        delegate :all_refs, :add_ref, :empty?, :bulk, :process_bulk_errors, :reset, to: :indexer

        def initialize(options)
          @options = options
          @client = client_klass.new(options)
          @indexer = indexer_klass.new(options, client)
        end

        def client_klass
          raise NotImplementedError
        end

        def indexer_klass
          raise NotImplementedError
        end
      end
    end
  end
end
