# frozen_string_literal: true

require 'date'

module QA
  module Page
    module Project
      module Settings
        class AccessTokens < Page::Base
          include Page::Component::AccessTokens
        end
      end
    end
  end
end
