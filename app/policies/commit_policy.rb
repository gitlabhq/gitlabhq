# frozen_string_literal: true

class CommitPolicy < BasePolicy
  delegate { @subject.project }
end
