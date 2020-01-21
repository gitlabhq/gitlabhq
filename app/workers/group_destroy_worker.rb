# frozen_string_literal: true

class GroupDestroyWorker
  include ApplicationWorker
  include ExceptionBacktrace

  feature_category :subgroups

  def perform(group_id, user_id)
    begin
      group = Group.find(group_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    Groups::DestroyService.new(group, user).execute
  end
end
