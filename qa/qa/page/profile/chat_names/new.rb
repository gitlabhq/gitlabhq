# frozen_string_literal: true

module QA
  module Page
    module Profile
      module ChatNames
        class New < Chemlab::Page
          button :authorize, value: /Authorize/i
        end
      end
    end
  end
end
