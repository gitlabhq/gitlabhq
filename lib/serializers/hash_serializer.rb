module Serializers
  # This serializer exports data as JSON,
  # but when loaded allows to access them with symbols
  class HashSerializer < ActiveRecord::Coders::JSON
    def self.dump(obj)
      ActiveSupport::JSON.encode(obj)
    end

    def self.load(json)
      ActiveSupport::JSON.decode(json).with_indifferent_access unless json.nil?
    end
  end
end
