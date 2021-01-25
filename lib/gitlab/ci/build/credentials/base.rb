# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Credentials
        class Base
          def type
            raise NotImplementedError
          end
        end
      end
    end
  end
end
