# frozen_string_literal: true

module Serializers
  # This serializer exports data as JSON,
  # but when loaded allows to access hashes with symbols
  class JSON
    def self.dump(obj)
      ActiveSupport::JSON.encode(obj)
    end

    def self.load(json)
      # this is required when `jsonb` is used by MySQL
      # which currently defaults to `text` field
      json = ActiveSupport::JSON.decode(json) if json.is_a?(String)

      self.deep_indifferent_access(json)
    end

    def self.deep_indifferent_access(data)
      if data.is_a?(Array)
        data.map { |item| self.deep_indifferent_access(item) }
      elsif data.is_a?(Hash)
        data.with_indifferent_access
      else
        data
      end
    end
  end
end
