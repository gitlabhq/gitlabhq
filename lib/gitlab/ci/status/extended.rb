module Gitlab
  module Ci
    module Status
      module Extended
        def matches?(_subject)
          raise NotImplementedError
        end
      end
    end
  end
end
