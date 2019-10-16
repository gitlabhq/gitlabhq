# frozen_string_literal: true

# Convert terminal stream to JSON
module Gitlab
  module Ci
    module Ansi2json
      def self.convert(ansi, state = nil)
        Converter.new.convert(ansi, state)
      end
    end
  end
end
