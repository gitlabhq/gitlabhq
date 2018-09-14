# frozen_string_literal: true

class GroupFinder
  include Gitlab::Allowable

  def initialize(current_user)
    @current_user = current_user
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute(*params)
    group = Group.find_by(*params)

    if can?(@current_user, :read_group, group)
      group
    else
      nil
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
