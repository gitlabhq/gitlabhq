# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        ##
        # Interpolation::Config represents a configuration artifact that we want to perform interpolation on.
        #
        class Config
          include Gitlab::Utils::StrongMemoize
          ##
          # Loading the YAML below would result in a hash having 12 nodes instead of 9,
          # because hash values are being counted before we recursively traverse them.
          #
          # test:
          #   spec:
          #     env: $[[ inputs.env ]]
          #
          # $[[ inputs.key ]]:
          #   name: $[[ inputs.key ]]
          #   script: my-value
          #
          # According to our benchmarks performed when developing this code, the worst-case scenario of processing
          # a hash with 500_000  nodes takes around 1 second and consumes around 225 megabytes of memory.
          #
          # The typical scenario, using just a few interpolations,
          # takes 250ms and consumes around 20 megabytes of memory.
          #
          # Given the above, 500_000 nodes should be an upper limit given that there are additional safeguards
          # present in other parts of the code.  Typical size of a YAML configuration with 500k nodes
          # might be around 10 megabytes, which is an order of magnitude higher than
          # the 1MB limit for loading YAML on GitLab.com
          #
          MAX_NODES = 500_000
          MAX_NODE_SIZE = 1024 * 1024 # 1MB

          TooManyNodesError = Class.new(StandardError)
          NodeTooLargeError = Class.new(StandardError)

          Visitor = Class.new do
            def initialize
              @visited = 0
            end

            def visit!
              @visited += 1

              raise Config::TooManyNodesError if @visited > Config::MAX_NODES
            end
          end

          attr_reader :errors

          def initialize(hash)
            @config = hash
            @errors = []
          end

          def to_h
            @config
          end

          ##
          # The replace! method will yield a block and replace each of the hash config nodes with
          # the return value of the block.
          #
          # It returns `nil` if there were errors found during the process.
          #
          def replace!(&block)
            recursive_replace(@config, Visitor.new, &block)
          rescue TooManyNodesError
            @errors.push('config too large')
            nil
          rescue NodeTooLargeError
            @errors.push('config node too large')
            nil
          end
          strong_memoize_attr :replace!

          def self.fabricate(config)
            case config
            when Hash
              new(config)
            when Interpolation::Config
              config
            else
              raise ArgumentError, 'unknown interpolation config'
            end
          end

          private

          def recursive_replace(config, visitor, &block)
            visitor.visit!

            case config
            when Hash
              recursive_replace_hash(config, visitor, &block)
            when Array
              recursive_replace_array(config, visitor, &block)
            when Symbol
              recursive_replace(config.to_s, visitor, &block)
            when String
              raise NodeTooLargeError if config.bytesize > MAX_NODE_SIZE

              yield config
            else
              config
            end
          end

          def recursive_replace_hash(config, visitor, &block)
            {}.tap do |new_hash|
              config.each_pair do |key, value|
                new_key = recursive_replace(key, visitor, &block)
                new_value = recursive_replace(value, visitor, &block)

                if new_key != key
                  new_hash[new_key] = new_value
                else
                  new_hash[key] = new_value
                end
              end
            end
          end

          def recursive_replace_array(config, visitor, &block)
            config.reduce([]) do |new_array, array_item|
              new_array_item = recursive_replace(array_item, visitor, &block)

              if insert_array_input_into_existing_array?(array_item, new_array_item)
                new_array + new_array_item
              else
                new_array << new_array_item
              end
            end
          end

          def insert_array_input_into_existing_array?(old_array_item, new_array_item)
            old_array_item.is_a?(String) && new_array_item.is_a?(Array)
          end
        end
      end
    end
  end
end
