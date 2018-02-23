class EpicPolicy < BasePolicy
  delegate { @subject.group }

  rule { can?(:read_epic) }.enable :read_epic_iid
end
