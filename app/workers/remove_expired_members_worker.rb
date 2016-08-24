class RemoveExpiredMembersWorker
  include Sidekiq::Worker

  def perform
    Member.expired.find_each do |member|
      begin
        Members::AuthorizedDestroyService.new(member).execute
      rescue => ex
        logger.error("Expired Member ID=#{member.id} cannot be removed - #{ex}")
      end
    end
  end
end
