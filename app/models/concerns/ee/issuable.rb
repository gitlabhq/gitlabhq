module EE
  module Issuable
    extend ActiveSupport::Concern

    def allows_multiple_assignees?
      supports_multiple_assignees? &&
        is_a?(Issue) && project.feature_available?(:multiple_issue_assignees)
    end
  end
end
