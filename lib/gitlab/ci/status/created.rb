# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Created < Status::Core
        def text
          s_('CiStatusText|Created')
        end

        def label
          s_('CiStatusLabel|created')
        end

        def icon
          'status_created'
        end

        def favicon
          'favicon_status_created'
        end

        def details_path
          nil
        end
      end
    end
  end
end
