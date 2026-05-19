# frozen_string_literal: true

class RemoveUnacceptedMemberInvitesWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :system_access
  urgency :low
  idempotent!

  EXPIRATION_THRESHOLD = 90.days
  BATCH_SIZE = 1_000

  def perform
    # We need to check for user_id IS NULL because we have accepted invitations
    # in the database where we did not clear the invite_token. We do not
    # want to accidentally delete those members.
    loop do
      batch = Member.invite
                    .created_before(EXPIRATION_THRESHOLD.ago)
                    .including_user_ids(nil)
                    .select(:id, :invite_email, :member_namespace_id) # needed for build_destroy_metadata
                    .limit(BATCH_SIZE)
                    .to_a

      break if batch.empty?

      destroy_metadata = build_destroy_metadata(batch)

      # rubocop: disable CodeReuse/ActiveRecord -- inline query for one-shot worker, no scope to extract
      deleted_count = Member.where(id: batch.map(&:id))
                            .delete_all
      # rubocop: enable CodeReuse/ActiveRecord

      enqueue_bulk_claims(destroy_metadata)

      break if deleted_count == 0
    end
  end

  private

  def build_destroy_metadata(batch)
    return [] unless Member.cells_claims_enabled_for_attribute?(:invite_email)

    batch.filter_map { |member| member.build_destroy_metadata_for_worker(:invite_email) }
  end

  def enqueue_bulk_claims(destroy_metadata)
    return if destroy_metadata.empty?

    destroy_metadata.each_slice(Cells::Claimable::BULK_CLAIMS_BATCH_SIZE) do |slice|
      Cells::BulkClaimsWorker.perform_async(Member.name, 'invite_email', { 'destroy_metadata' => slice })
    end
  end
end
