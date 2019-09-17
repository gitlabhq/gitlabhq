# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class GitAccess < Page::Base
          include Page::Component::LegacyClonePanel
        end
      end
    end
  end
end
