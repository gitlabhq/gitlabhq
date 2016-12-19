module Gitlab
  module Ci
    module Status
      class Failed < Status::Core
        def text
          'failed'
        end

        def label
          'failed'
        end

        def icon
          'icon_status_failed'
        end

        def pipeline_email_template
          :pipeline_failed_email
        end

        def pipeline_email_status
          'failed'
        end
      end
    end
  end
end
