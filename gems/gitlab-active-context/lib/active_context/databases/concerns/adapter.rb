# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module Adapter
        attr_reader :options, :prefix, :client, :indexer, :executor

        DEFAULT_PREFIX = 'gitlab_active_context'
        DEFAULT_SEPARATOR = '_'

        delegate :search, to: :client
        delegate :all_refs, :add_ref, :empty?, :bulk, :process_bulk_errors, :reset, to: :indexer

        def initialize(options)
          @options = options
          @prefix = options[:prefix] || DEFAULT_PREFIX
          @client = client_klass.new(options)
          @indexer = indexer_klass.new(options, client)
          @executor = executor_klass.new(self)
        end

        def client_klass
          raise NotImplementedError
        end

        def indexer_klass
          raise NotImplementedError
        end

        def executor_klass
          raise NotImplementedError
        end

        def full_collection_name(name)
          [prefix, name].compact.join(separator)
        end

        def separator
          DEFAULT_SEPARATOR
        end
      end
    end
  end
end
