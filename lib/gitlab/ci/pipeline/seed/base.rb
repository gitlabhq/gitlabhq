module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Base
          def attributes
            raise NotImplementedError
          end

          def included?
            raise NotImplementedError
          end

          def to_resource
            raise NotImplementedError
          end
        end
      end
    end
  end
end
