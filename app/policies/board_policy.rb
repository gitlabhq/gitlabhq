# frozen_string_literal: true

class BoardPolicy < BasePolicy
  delegate { @subject.parent }

  condition(:is_group_board) { @subject.group_board? }

  rule { is_group_board ? can?(:read_group) : can?(:read_project) }.enable :read_parent

  rule { is_group_board & can?(:read_group) }.policy do
    enable :read_milestone
    enable :read_issue
  end
end
