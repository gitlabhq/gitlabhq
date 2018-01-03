class ProjectLabelPolicy < BasePolicy
  delegate { @subject.project }
end
