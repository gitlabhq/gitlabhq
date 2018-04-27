# rubocop:disable Naming/FileName
module QA
  module Runtime
    module Key
      class ED25519 < Base
        def initialize
          super('ed25519', 256)
        end
      end
    end
  end
end
