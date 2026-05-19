# frozen_string_literal: true

module ClickHouse
  module SchemaCache
    class Table
      attr_reader :name, :engine, :engine_full, :partition_key, :sampling_key, :settings, :columns

      def initialize(**attrs)
        @name = attrs.fetch(:name)
        @engine = attrs.fetch(:engine)
        @engine_full = attrs.fetch(:engine_full)
        @partition_key = attrs.fetch(:partition_key)
        @primary_key_raw = attrs.fetch(:primary_key)
        @sorting_key_raw = attrs.fetch(:sorting_key)
        @sampling_key = attrs.fetch(:sampling_key)
        @settings = attrs.fetch(:settings)
        @columns = attrs.fetch(:columns)
      end

      def column(column_name)
        columns_by_name[column_name.to_s]
      end

      def column_names
        columns.map(&:name)
      end

      def primary_key
        @primary_key ||= resolve_key(@primary_key_raw)
      end

      def sorting_key
        @sorting_key ||= resolve_key(@sorting_key_raw)
      end

      def engine_params
        @engine_params ||= parse_engine_params
      end

      def to_h
        {
          'name' => name,
          'engine' => engine,
          'engine_full' => engine_full,
          'partition_key' => partition_key,
          'primary_key' => @primary_key_raw,
          'sorting_key' => @sorting_key_raw,
          'sampling_key' => sampling_key,
          'settings' => settings,
          'columns' => columns.map(&:to_h)
        }.compact_blank
      end

      private

      def columns_by_name
        @columns_by_name ||= columns.index_by(&:name)
      end

      def resolve_key(raw)
        return [] if raw.blank?

        split_top_level_commas(raw).map { |part| column(part) || part }
      end

      def parse_engine_params
        return [] if engine_full.blank?

        open_idx = engine_full.index('(')
        return [] unless open_idx

        prefix = engine_full[0...open_idx].strip
        return [] unless prefix == engine || prefix == "`#{engine}`"

        inner = engine_full[(open_idx + 1)..]
        closing_idx = find_closing_paren(inner)
        return [] unless closing_idx

        split_top_level_commas(inner[0...closing_idx])
      end

      def find_closing_paren(str)
        depth = 1
        string_char = nil
        escape = false
        result = nil

        str.each_char.with_index do |char, idx|
          if string_char
            if escape
              escape = false
            elsif char == '\\'
              escape = true
            elsif char == string_char
              string_char = nil
            end
          else
            case char
            when "'", '`' then string_char = char
            when '(' then depth += 1
            when ')'
              depth -= 1
              if depth == 0
                result = idx
                break
              end
            end
          end
        end

        result
      end

      # resolves complex key like (column1, myFunc1(param1, param2), column2)
      def split_top_level_commas(raw)
        parts = []
        buffer = +''
        depth = 0
        string_char = nil
        escape = false

        raw.each_char do |char|
          if string_char
            buffer << char

            if escape
              escape = false
            elsif char == '\\'
              escape = true
            elsif char == string_char
              string_char = nil
            end
          elsif char == ',' && depth == 0
            parts << buffer.strip
            buffer = +''
          else
            buffer << char

            case char
            when "'", '`' then string_char = char
            when '(' then depth += 1
            when ')' then depth -= 1
            end
          end
        end

        parts << buffer.strip
        parts.reject(&:empty?)
      end
    end
  end
end
