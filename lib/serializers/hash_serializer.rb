module Serializers
  # This serializer exports data as JSON,
  # but when loaded allows to access them with symbols
  class HashSerializer
    def self.dump(obj)
      ActiveSupport::JSON.encode(obj)
    end

    def self.load(json)
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
