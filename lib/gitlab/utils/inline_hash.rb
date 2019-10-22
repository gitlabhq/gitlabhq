# frozen_string_literal: true

module Gitlab
  module Utils
    module InlineHash
      extend self

      # Transforms a Hash into an inline Hash by merging its nested keys.
      #
      # Input
      #
      #  {
      #    'root_param' => 'Root',
      #    12 => 'number',
      #    symbol: 'symbol',
      #    nested_param: {
      #      key: 'Value'
      #    },
      #    'very' => {
      #      'deep' => {
      #        'nested' => {
      #          12 => 'Deep nested value'
      #        }
      #      }
      #    }
      #  }
      #
      #
      # Result
      #
      #  {
      #    'root_param' => 'Root',
      #     12 => 'number',
      #     symbol: symbol,
      #    'nested_param.key' => 'Value',
      #    'very.deep.nested.12' => 'Deep nested value'
      #  }
      #
      def merge_keys(hash, prefix: nil, connector: '.')
        result = {}
        pairs =
          if prefix
            base_prefix = "#{prefix}#{connector}"
            hash.map { |key, value| ["#{base_prefix}#{key}", value] }
          else
            hash.to_a
          end

        until pairs.empty?
          key, value = pairs.shift

          if value.is_a?(Hash)
            value.each { |k, v| pairs.unshift ["#{key}#{connector}#{k}", v] }
          else
            result[key] = value
          end
        end

        result
      end
    end
  end
end
