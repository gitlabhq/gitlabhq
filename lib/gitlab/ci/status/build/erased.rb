module Gitlab
  module Ci
    module Status
      module Build
        class Erased < Status::Extended
          def illustration
            {
              image: 'illustrations/erased-log_empty.svg',
              size: 'svg-430',
              title: _('Job has been erased')
            }
          end

          def self.matches?(build, user)
            build.erased?
          end
        end
      end
    end
  end
end
