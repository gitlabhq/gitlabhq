# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Group
        module Common
          def has_details?
            false
          end

          def details_path
            nil
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
