module Gitlab
  module Ci
    module Status
      module Extended
        def matches?(_subject, _user)
          raise NotImplementedError
        end
      end
    end
  end
end
