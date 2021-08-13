# frozen_string_literal: true

module QA
  module Page
    module Project
      module Wiki
        class Edit < Base
          include Page::Component::WikiPageForm
          include Page::Component::WikiSidebar
          include Page::Component::ContentEditor
        end
      end
    end
  end
end
