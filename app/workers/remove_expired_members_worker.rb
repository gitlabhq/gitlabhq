class RemoveExpiredMembersWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Member.expired.find_each do |member|
      begin
        Members::AuthorizedDestroyService.new.execute(member)
      rescue => ex
        logger.error("Expired Member ID=#{member.id} cannot be removed - #{ex}")
      end
    end
  end
end
