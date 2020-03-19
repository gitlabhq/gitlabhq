# frozen_string_literal: true

class RemoveExpiredMembersWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :authentication_and_authorization
  worker_resource_boundary :cpu

  def perform
    Member.expired.find_each do |member|
      Members::DestroyService.new.execute(member, skip_authorization: true)
    rescue => ex
      logger.error("Expired Member ID=#{member.id} cannot be removed - #{ex}")
    end
  end
end
