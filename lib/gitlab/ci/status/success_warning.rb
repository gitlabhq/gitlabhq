# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      ##
      # Extended status used when pipeline or stage passed conditionally.
      # This means that failed jobs that are allowed to fail were present.
      #
      class SuccessWarning < Status::Extended
        def text
          s_('CiStatusText|Warning')
        end

        def label
          s_('CiStatusLabel|passed with warnings')
        end

        def icon
          'status_warning'
        end

        def name
          'SUCCESS_WITH_WARNINGS'
        end

        def group
          'success-with-warnings'
        end

        def self.matches?(subject, user)
          subject.success? && subject.has_warnings?
        end
      end
    end
  end
end
