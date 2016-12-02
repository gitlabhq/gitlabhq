module Gitlab::Ci
  module Status
    module Extended
      module Base
        def matches?(_subject)
          raise NotImplementedError
        end
      end
    end
  end
end
