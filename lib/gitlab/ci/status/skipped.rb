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
          Gitlab::Favicon.status('skipped')
        end
      end
    end
  end
end
