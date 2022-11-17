# frozen_string_literal: true

class CommitPolicy < BasePolicy
  delegate { @subject.project }

  rule { can?(:read_code) }.enable :read_commit
  rule { ~can?(:read_commit) }.prevent :create_note
end
