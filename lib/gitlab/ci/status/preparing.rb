# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Preparing < Status::Core
        def text
          s_('CiStatusText|preparing')
        end

        def label
          s_('CiStatusLabel|preparing')
        end

        ##
        # TODO: shared with 'created'
        # until we get one for 'preparing'
        #
        def icon
          'status_created'
        end

        ##
        # TODO: shared with 'created'
        # until we get one for 'preparing'
        #
        def favicon
          'favicon_status_created'
        end
      end
    end
  end
end
