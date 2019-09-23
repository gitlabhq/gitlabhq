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
      #    nested_param: {
      #      key: 'Value'
      #    },
      #    'very' => {
      #      'deep' => {
      #        'nested' => {
      #          'param' => 'Deep nested value'
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
      #    'nested_param.key' => 'Value',
      #    'very.deep.nested.param' => 'Deep nested value'
      #  }
      #
      def merge_keys(hash, prefix: nil, connector: '.')
        result = {}
        base_prefix = prefix ? "#{prefix}#{connector}" : ''
        pairs = hash.map { |key, value| ["#{base_prefix}#{key}", value] }

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
