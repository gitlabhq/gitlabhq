class CommitStatusPolicy < BasePolicy
  delegate { @subject.project }

  %w[read create update admin].each do |action|
    rule { ~can?(:"#{action}_commit_status") }.prevent :"#{action}_build"
  end
end
