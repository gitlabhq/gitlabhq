# frozen_string_literal: true

module Import
  module Github
    module Notes
      class CreateService < ::Notes::CreateService
        # Github does not have support to quick actions in notes (like /assign)
        # Therefore, when importing notes we skip the quick actions processing
        def quick_actions_supported?(_note)
          false
        end
      end
    end
  end
end
