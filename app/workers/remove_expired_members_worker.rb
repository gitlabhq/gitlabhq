# frozen_string_literal: true

class RemoveExpiredMembersWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue

  feature_category :system_access
  worker_resource_boundary :cpu

  BATCH_SIZE = 1000
  BATCH_DELAY = 10.seconds

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(cursor = nil)
    @updated_count = 0
    paginator = paginate(cursor)

    paginator.each { |member| process_member(member) }

    status = paginator.has_next_page? ? :limit_reached : :completed
    log_extra_metadata_on_done(:result,
      status: status,
      updated_rows: @updated_count
    )

    return unless paginator.has_next_page?

    self.class.perform_in(BATCH_DELAY, paginator.cursor_for_next_page)
  end

  private

  def paginate(cursor)
    Member.expired
      .includes(:user, :source)
      .order(expires_at: :desc, id: :desc)
      .keyset_paginate(cursor: cursor, per_page: BATCH_SIZE)
  end

  def process_member(member)
    context = {
      user: member.user,
      # The ApplicationContext will reject type-mismatches. So a GroupMemeber will only populate `namespace`.
      # while a `ProjectMember` will populate `project
      project: member.source,
      namespace: member.source
    }
    with_context(context) do
      Members::DestroyService.new.execute(member, skip_authorization: true, skip_subresources: true)

      expired_user = member.user

      if expired_user.project_bot?
        Users::DestroyService.new(nil).execute(expired_user, {
          skip_authorization: true,
          project_bot_resource: member.source,
          reason_for_deletion: "Membership expired"
        })
      end

      @updated_count += 1
    end
  rescue StandardError => ex
    logger.error("Expired Member ID=#{member.id} cannot be removed - #{ex}")
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ex)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
