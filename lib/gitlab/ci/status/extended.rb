module Gitlab
  module Ci
    module Status
      module Extended
        extend ActiveSupport::Concern

        class_methods do
          def matches?(_subject, _user)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
