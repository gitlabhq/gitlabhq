# frozen_string_literal: true

class RemoveUnacceptedMemberInvitesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :authentication_and_authorization
  tags :exclude_from_kubernetes
  urgency :low
  idempotent!

  EXPIRATION_THRESHOLD = 90.days
  BATCH_SIZE = 10_000

  def perform
    # We need to check for user_id IS NULL because we have accepted invitations
    # in the database where we did not clear the invite_token. We do not
    # want to accidentally delete those members.
    loop do
      # rubocop: disable CodeReuse/ActiveRecord
      inner_query = Member
                      .select(:id)
                      .invite
                      .created_before(EXPIRATION_THRESHOLD.ago)
                      .where(user_id: nil)
                      .limit(BATCH_SIZE)

      records_deleted = Member.where(id: inner_query).delete_all
      # rubocop: enable CodeReuse/ActiveRecord

      break if records_deleted == 0
    end
  end
end
