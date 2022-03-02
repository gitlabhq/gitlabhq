# frozen_string_literal: true

module Serializers
  class UnsafeJson
    class << self
      def dump(obj)
        obj.to_json(unsafe: true)
      end

      delegate :load, to: :JSON
    end
  end
end
