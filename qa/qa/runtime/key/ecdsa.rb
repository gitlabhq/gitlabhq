# frozen_string_literal: true

module QA
  module Runtime
    module Key
      class ECDSA < Base
        def initialize(bits = 521)
          super('ecdsa', bits)
        end
      end
    end
  end
end
