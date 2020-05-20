# frozen_string_literal: true

module DesignManagement
  class VersionPolicy < ::BasePolicy
    # The IssuePolicy will delegate to the ProjectPolicy
    delegate { @subject.issue }
  end
end
