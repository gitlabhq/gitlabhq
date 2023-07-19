# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      module Downstream
        class RawVariableGenerator < Base
          def for(item)
            [{ key: item.key, value: item.value, raw: true }]
          end
        end
      end
    end
  end
end
