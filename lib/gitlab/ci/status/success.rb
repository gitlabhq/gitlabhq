module Gitlab
  module Ci
    module Status
      class Success < Status::Core
        def text
          'passed'
        end

        def label
          'passed'
        end

        def icon
          'icon_status_success'
        end

        def pipeline_email_template
          if subject.recovered? || subject.first_success?
            :pipeline_success_email
          end
        end

        def pipeline_email_status
          if subject.recovered?
            'recovered'
          else
            'passed'
          end
        end
      end
    end
  end
end
