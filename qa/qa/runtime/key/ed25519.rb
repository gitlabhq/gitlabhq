# frozen_string_literal: true

module QA
  module Runtime
    module Key
      class ED25519 < Base
        def initialize(bits = 256)
          super('ed25519', bits)
        end
      end
    end
  end
end
