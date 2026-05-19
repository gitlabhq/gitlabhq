# frozen_string_literal: true

module Gitlab
  module Ci
    module Ansi2json
      module V2
        def self.convert(ansi, state = nil)
          Converter.new.convert(ansi, state)
        end
      end
    end
  end
end
