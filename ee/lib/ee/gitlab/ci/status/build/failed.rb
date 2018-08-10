# frozen_string_literal: true
module EE
  module Gitlab
    module Ci
      module Status
        module Build
          module Failed
            EE_REASONS = {
              protected_environment_failure: 'protected environment failure'
            }.freeze
          end
        end
      end
    end
  end
end
