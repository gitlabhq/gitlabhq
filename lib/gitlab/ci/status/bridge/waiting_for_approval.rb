# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class WaitingForApproval < Status::Extended
          ## Extended in EE
          def self.matches?(_bridge, _user)
            false
          end
        end
      end
    end
  end
end

Gitlab::Ci::Status::Bridge::WaitingForApproval.prepend_mod_with('Gitlab::Ci::Status::Bridge::WaitingForApproval')
