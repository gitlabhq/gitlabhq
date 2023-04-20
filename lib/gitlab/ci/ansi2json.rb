# frozen_string_literal: true

# Convert terminal stream to JSON
module Gitlab
  module Ci
    module Ansi2json
      def self.convert(ansi, state = nil, verify_state: false)
        Converter.new.convert(ansi, state, verify_state: verify_state)
      end
    end
  end
end
