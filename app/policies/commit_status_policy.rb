# frozen_string_literal: true

class CommitStatusPolicy < BasePolicy
  delegate { @subject.project }
end
