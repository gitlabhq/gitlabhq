# frozen_string_literal: true

module Gitlab
  module Database
    # Renders rows as aligned text columns and returns the lines.
    # Callers own the IO, indentation and colors.
    class AsciiTable
      def initialize(rows, headers: nil, gap: '  ', rule_gap: nil)
        @headers = headers.presence&.map(&:to_s)
        @rows = rows.map { |row| row.map(&:to_s) }
        @gap = gap
        @rule_gap = rule_gap || gap
      end

      def lines
        result = []

        if headers
          result << join(headers, gap)
          result << join(widths.map { |width| '-' * width }, rule_gap)
        end

        rows.each { |row| result << join(row, gap) }
        result
      end

      private

      attr_reader :headers, :rows, :gap, :rule_gap

      def join(cells, separator)
        cells.each_with_index.map { |cell, index| cell.ljust(widths[index]) }.join(separator)
      end

      def widths
        @widths ||= begin
          all_rows = [headers, *rows].compact

          Array.new(all_rows.map(&:size).max) do |index|
            all_rows.map { |row| row[index].to_s.length }.max
          end
        end
      end
    end
  end
end
