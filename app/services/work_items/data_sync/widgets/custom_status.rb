# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class CustomStatus < Base
        # Need this class to make spec pass at https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/models/ee/work_items/widget_definition_spec.rb#L49
        # Will be implemented as part of https://gitlab.com/groups/gitlab-org/-/epics/14793
      end
    end
  end
end
