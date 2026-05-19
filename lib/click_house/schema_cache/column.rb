# frozen_string_literal: true

module ClickHouse
  module SchemaCache
    class Column
      DEFAULTS = {
        position: nil,
        default_kind: '',
        default_expression: '',
        comment: '',
        compression_codec: '',
        is_in_partition_key: false,
        is_in_sorting_key: false,
        is_in_primary_key: false,
        is_in_sampling_key: false
      }.freeze

      attr_reader :name, :type, :position, :default_kind, :default_expression,
        :comment, :compression_codec, :is_in_partition_key, :is_in_sorting_key,
        :is_in_primary_key, :is_in_sampling_key

      def initialize(name:, type:, **kwargs)
        options = DEFAULTS.merge(kwargs)
        @name = name
        @type = type
        @position = options[:position]
        @default_kind = options[:default_kind]
        @default_expression = options[:default_expression]
        @comment = options[:comment]
        @compression_codec = options[:compression_codec]
        @is_in_partition_key = options[:is_in_partition_key]
        @is_in_sorting_key = options[:is_in_sorting_key]
        @is_in_primary_key = options[:is_in_primary_key]
        @is_in_sampling_key = options[:is_in_sampling_key]
      end

      def nullable?
        type.to_s.start_with?('Nullable(')
      end

      def to_h
        {
          'name' => name,
          'type' => type,
          'default_kind' => default_kind,
          'default_expression' => default_expression,
          'comment' => comment,
          'compression_codec' => compression_codec,
          'is_in_partition_key' => is_in_partition_key,
          'is_in_sorting_key' => is_in_sorting_key,
          'is_in_primary_key' => is_in_primary_key,
          'is_in_sampling_key' => is_in_sampling_key
        }.compact_blank
      end
    end
  end
end
