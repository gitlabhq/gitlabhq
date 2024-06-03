# frozen_string_literal: true

class GroupDestroyWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :groups_and_projects

  idempotent!
  deduplicate :until_executed, ttl: 2.hours

  def perform(group_id, user_id)
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464673')

    begin
      group = Group.find(group_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    user = User.find(user_id)

    Groups::DestroyService.new(group, user).execute
  end
end
