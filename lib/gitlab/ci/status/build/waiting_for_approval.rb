# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class WaitingForApproval < Status::Extended
          ## Extended in EE
          def self.matches?(build, user)
            false
          end
        end
      end
    end
  end
end

Gitlab::Ci::Status::Build::WaitingForApproval.prepend_mod_with('Gitlab::Ci::Status::Build::WaitingForApproval')
