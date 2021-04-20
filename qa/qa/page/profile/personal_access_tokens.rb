# frozen_string_literal: true

require 'date'

module QA
  module Page
    module Profile
      class PersonalAccessTokens < Page::Base
        include Page::Component::AccessTokens
      end
    end
  end
end
