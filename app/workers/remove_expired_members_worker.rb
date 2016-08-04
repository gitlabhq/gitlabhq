class RemoveExpiredMembersWorker
  include Sidekiq::Worker

  def perform
    Member.includes(:created_by).where("expires_at <= ?", Time.current).find_each do |member|
      begin
        Members::DestroyService.new(member, member.created_by).execute
      rescue => ex
        logger.error("Expired Member ID=#{member.id} cannot be removed - #{ex}")
      end
    end
  end
end
