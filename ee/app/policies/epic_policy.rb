class EpicPolicy < BasePolicy
  delegate { @subject.group }

  rule { can?(:read_epic) }.policy do
    enable :read_epic_iid
    enable :read_note
  end

  rule { can?(:update_epic) }.policy do
    enable :create_note
  end

  rule { can?(:create_note) }.enable :award_emoji
end
