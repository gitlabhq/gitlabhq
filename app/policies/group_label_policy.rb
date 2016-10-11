class GroupLabelPolicy < BasePolicy
  def rules
    delegate! @subject.group
  end
end
