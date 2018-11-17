# frozen_string_literal: true

module Gitlab
  module ImportExport
    class HashUtil
      def self.deep_symbolize_array!(array)
        return if array.blank?

        array.map! do |hash|
          hash.deep_symbolize_keys!

          yield(hash) if block_given?

          hash
        end
      end

      def self.deep_symbolize_array_with_date!(array)
        self.deep_symbolize_array!(array) do |hash|
          hash.select { |k, _v| k.to_s.end_with?('_date') }.each do |key, value|
            hash[key] = Time.zone.parse(value)
          end
        end
      end
    end
  end
end
