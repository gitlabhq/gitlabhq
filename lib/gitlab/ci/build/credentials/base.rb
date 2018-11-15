# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Credentials
        class Base
          def type
            self.class.name.demodulize.underscore
          end
        end
      end
    end
  end
end
