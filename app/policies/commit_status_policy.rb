# frozen_string_literal: true

class CommitStatusPolicy < BasePolicy
  delegate { @subject.project }

  rule { ~can?(:read_commit_status) }.prevent :read_build
end
