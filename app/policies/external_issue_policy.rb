class ExternalIssuePolicy < BasePolicy
  delegate { @subject.project }
end
