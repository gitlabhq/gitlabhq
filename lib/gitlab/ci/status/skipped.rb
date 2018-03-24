module Gitlab
  module Ci
    module Status
      class Skipped < Status::Core
        def text
          s_('CiStatusText|skipped')
        end

        def label
          s_('CiStatusLabel|skipped')
        end

        def icon
          'status_skipped'
        end

        def favicon
          'favicon_status_skipped'
        end

        def illustration
          'skipped-job_empty'
        end
      end
    end
  end
end
