# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Edit < Base
          include Page::Component::WikiPageForm
          include Page::Component::WikiSidebar
        end
      end
    end
  end
end
