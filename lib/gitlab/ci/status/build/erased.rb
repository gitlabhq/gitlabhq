# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Erased < Status::Extended
          def illustration
            {
              image: 'illustrations/empty-state/empty-projects-deleted-md.svg',
              size: '',
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
