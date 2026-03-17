# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- existing class moved from EE to CE
# rubocop:disable Gitlab/BoundedContexts -- existing class moved from EE to CE
# rubocop:disable Gitlab/NamespacedClass -- existing class moved from EE to CE
class AdjournedGroupDeletionWorker
  include ::Gitlab::InternalEventsTracking
  include ApplicationWorker

  data_consistency :sticky

  include CronjobQueue

  INTERVAL = 20.seconds.to_i

  feature_category :groups_and_projects

  def perform
    deletion_cutoff = Gitlab::CurrentSettings.deletion_adjourned_period.days.ago.to_date

    Group.with_route
      .deletion_scheduled_before(deletion_cutoff)
      .with_deletion_scheduled_by_user
      .find_each(batch_size: 100) # rubocop: disable CodeReuse/ActiveRecord -- existing class moved from EE to CE
      .with_index do |group, index|
      delay = index * INTERVAL

      user = group.deletion_scheduled_by_user

      with_context(namespace: group, user: user) do
        track_event(group, user)

        Namespaces::Groups::AdjournedDeletionService
          .new(group: group, current_user: user, params: { delay: delay })
          .execute
      end
    end
  end

  private

  def track_event(group, user)
    track_internal_event(
      'trigger_delete_on_group',
      namespace: group,
      user: user,
      label: 'worker',
      property: 'true',
      actor: 'system'
    )
  end
end
# rubocop:enable Scalability/IdempotentWorker
# rubocop:enable Gitlab/BoundedContexts
# rubocop:enable Gitlab/NamespacedClass
