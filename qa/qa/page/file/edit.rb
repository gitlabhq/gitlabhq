# frozen_string_literal: true

module QA
  module Page
    module File
      class Edit < Page::Base
        include Shared::CommitMessage
        include Shared::CommitButton
        include Shared::Editor
      end
    end
  end
end
