# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      TIMESTAMP_KEYS = %i[created_at updated_at merged_at].freeze

      # Converts a Hash with String based keys to one that can be used by the
      # various Representation classes.
      #
      # Example:
      #
      #     Representation.symbolize_hash('number' => 10) # => { number: 10 }
      def self.symbolize_hash(raw_hash = nil)
        hash = raw_hash.deep_symbolize_keys

        TIMESTAMP_KEYS.each do |key|
          hash[key] = Time.parse(hash[key]) if hash[key].is_a?(String)
        end

        hash
      end
    end
  end
end
