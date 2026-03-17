# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- existing class moved from EE to CE
# rubocop:disable Gitlab/BoundedContexts -- existing class moved from EE to CE
# rubocop:disable Gitlab/NamespacedClass -- existing class moved from EE to CE
class AdjournedProjectsDeletionCronWorker
  include ::Gitlab::InternalEventsTracking
  include ApplicationWorker

  data_consistency :sticky

  include CronjobQueue

  INTERVAL = 3.seconds.to_i

  feature_category :compliance_management

  def perform
    deletion_cutoff = Gitlab::CurrentSettings.deletion_adjourned_period.days.ago.to_date

    Project.with_route.with_deleting_user.marked_for_deletion_before(deletion_cutoff).find_each(batch_size: 100).with_index do |project, index| # rubocop: disable CodeReuse/ActiveRecord -- existing class moved from EE to CE
      delay = index * INTERVAL

      with_context(project: project, user: project.deleting_user) do
        track_event(project)

        AdjournedProjectDeletionWorker.perform_in(delay, project.id)
      end
    end
  end

  private

  def track_event(project)
    track_internal_event(
      'trigger_delete_on_project',
      project: project,
      namespace: project.namespace,
      user: project.deleting_user,
      label: 'worker',
      property: 'true',
      actor: 'system'
    )
  end
end
# rubocop:enable Scalability/IdempotentWorker
# rubocop:enable Gitlab/BoundedContexts
# rubocop:enable Gitlab/NamespacedClass
