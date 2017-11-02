class EpicPolicy < BasePolicy
  delegate { @subject.group }
end
