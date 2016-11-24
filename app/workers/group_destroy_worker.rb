class GroupDestroyWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(group_id, user_id)
    begin
      group = Group.with_deleted.find(group_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    DestroyGroupService.new(group, user).execute
  end
end
