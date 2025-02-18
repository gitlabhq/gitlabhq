# frozen_string_literal: true

# rubocop: disable Gitlab/ModuleWithInstanceVariables -- this is a concern

module ActiveContext
  module Databases
    module Concerns
      module Indexer
        attr_reader :options, :client, :refs

        def initialize(options, client)
          @options = options
          @client = client
          @refs = []
        end

        def all_refs
          refs
        end

        # Adds a reference to the refs array
        #
        # @param ref [Object] The reference to add
        # @return [Boolean] True if bulk processing should be forced, e.g., when a size threshold is reached
        def add_ref(ref)
          raise NotImplementedError
        end

        # Checks if nothing should be processed
        #
        # @return [Boolean] True if bulk processing should be skipped
        def empty?
          raise NotImplementedError
        end

        # Performs bulk processing on the refs array
        #
        # @return [Object] The result of bulk processing
        def bulk
          raise NotImplementedError
        end

        # Processes errors from bulk operation
        #
        # @param result [Object] The result from the bulk operation
        # @return [Array] Any failures that occurred during bulk processing
        def process_bulk_errors(_result)
          raise NotImplementedError
        end

        # Resets the adapter to a clean state
        def reset
          @refs = []
          # also reset anything that builds up from the refs array
        end
      end
    end
  end
end

# rubocop: enable Gitlab/ModuleWithInstanceVariables
