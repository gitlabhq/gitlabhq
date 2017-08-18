module Gitlab
  module Ci
    module Status
      module Build
        class Action < Status::Extended
          def label
            if has_action?
              @status.label
            else
              "#{@status.label} (not allowed)"
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
