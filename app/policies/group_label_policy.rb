class GroupLabelPolicy < BasePolicy
  delegate { @subject.group }
end
