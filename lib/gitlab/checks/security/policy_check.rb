# frozen_string_literal: true

module Gitlab
  module Checks
    module Security
      class PolicyCheck < BaseSingleChecker
        def validate!; end
      end
    end
  end
end

Gitlab::Checks::Security::PolicyCheck.prepend_mod
