module Gitlab
  module Ci
    module Status
      ##
      # Abstract extended status used when pipeline/stage/build passed
      # conditionally.
      #
      # This means that failed jobs that are allowed to fail were present.
      #
      class SuccessWarning < SimpleDelegator
        include Status::Extended

        def text
          'passed'
        end

        def label
          'passed with warnings'
        end

        def icon
          'icon_status_warning'
        end

        def group
          'success_with_warnings'
        end

        def self.matches?(subject, user)
          raise NotImplementedError
        end
      end
    end
  end
end
