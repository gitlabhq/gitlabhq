# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Retried < Status::Extended
          def status_tooltip
            @status.status_tooltip + " (retried)"
          end

          def self.matches?(build, user)
            build.retried?
          end
        end
      end
    end
  end
end
