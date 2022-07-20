# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class AccessTokens < Page::Base
          include Page::Component::AccessTokens
          include Page::Component::ConfirmModal
        end
      end
    end
  end
end
