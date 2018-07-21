class CommitPolicy < BasePolicy
  delegate { @subject.project }
end
