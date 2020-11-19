# frozen_string_literal: true

class RemoveExpiredMembersWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :authentication_and_authorization
  worker_resource_boundary :cpu

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    Member.expired.preload(:user).find_each do |member|
      Members::DestroyService.new.execute(member, skip_authorization: true)

      expired_user = member.user

      if expired_user.project_bot?
        Users::DestroyService.new(nil).execute(expired_user, skip_authorization: true)
      end
    rescue => ex
      logger.error("Expired Member ID=#{member.id} cannot be removed - #{ex}")
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
