# frozen_string_literal: true

class CommitPolicy < BasePolicy
  delegate { @subject.project }

  rule { can?(:download_code) }.enable :read_commit
end
