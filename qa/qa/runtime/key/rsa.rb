module QA
  module Runtime
    module Key
      class RSA < Base
        def initialize(bits = 4096)
          super('rsa', bits)
        end
      end
    end
  end
end
