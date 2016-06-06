module Gitlab
  module Ci
    class Config
      module Entry
        class Global < BaseEntry
          def allowed_keys
            []
          end
        end
      end
    end
  end
end
