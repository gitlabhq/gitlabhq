# frozen_string_literal: true

class RemoveExpiredMembersWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include CronjobQueue

  feature_category :authentication_and_authorization
  worker_resource_boundary :cpu

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    Member.expired.preload(:user, :source).find_each do |member|
      context = {
        user: member.user,
        # The ApplicationContext will reject type-mismatches. So a GroupMemeber will only populate `namespace`.
        # while a `ProjectMember` will populate `project
        project: member.source,
        namespace: member.source
      }
      with_context(context) do
        Members::DestroyService.new.execute(member, skip_authorization: true)

        expired_user = member.user

        if expired_user.project_bot?
          Users::DestroyService.new(nil).execute(expired_user, skip_authorization: true)
        end
      end
    rescue StandardError => ex
      logger.error("Expired Member ID=#{member.id} cannot be removed - #{ex}")
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
