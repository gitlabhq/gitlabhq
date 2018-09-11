# frozen_string_literal: true

class GroupFinder
  include Gitlab::Allowable

  def initialize(current_user)
    @current_user = current_user
  end

  def execute(*params)
    group = Group.find_by(*params)

    if can?(@current_user, :read_group, group)
      group
    else
      nil
    end
  end
end
