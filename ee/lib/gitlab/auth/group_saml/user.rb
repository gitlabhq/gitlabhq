module Gitlab
  module Auth
    module GroupSaml
      class User
        def initialize(auth_hash)
          raise NotImplementedError
        end
      end
    end
  end
end
