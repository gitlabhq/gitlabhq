module Serializers
  # This serializer exports data as JSON,
  # but when loaded allows to access them with symbols
  module HashSerializer
    extend self

    def dump(hash)
      hash.to_json
    end

    def load(hash)
      hash = JSON.load(hash) if hash.is_a?(String)

      (hash || {}).with_indifferent_access
    end
  end
end
