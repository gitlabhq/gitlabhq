module QA
  module Runtime
    module Key
      class DSA < Base
        def initialize
          super('dsa', 1024)
        end
      end
    end
  end
end
