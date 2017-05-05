module Gitlab
  module Ci
    module Status
      module Build
        class Action < SimpleDelegator
          include Status::Extended

          def label
            if has_action?
              __getobj__.label
            else
              "#{__getobj__.label} (not allowed)"
            end
          end

          def self.matches?(build, user)
            build.action?
          end
        end
      end
    end
  end
end
