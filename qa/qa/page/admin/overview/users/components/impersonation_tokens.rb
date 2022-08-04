# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Overview
        module Users
          module Components
            class ImpersonationTokens < Page::Base
              include Page::Component::AccessTokens
              include Page::Component::ConfirmModal
            end
          end
        end
      end
    end
  end
end
