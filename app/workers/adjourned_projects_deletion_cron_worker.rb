# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- existing class moved from EE to CE
# rubocop:disable Gitlab/BoundedContexts -- existing class moved from EE to CE
# rubocop:disable Gitlab/NamespacedClass -- existing class moved from EE to CE
class AdjournedProjectsDeletionCronWorker
  include ApplicationWorker

  data_consistency :sticky

  include CronjobQueue

  INTERVAL = 10.seconds.to_i

  feature_category :compliance_management

  def perform
    deletion_cutoff = Gitlab::CurrentSettings.deletion_adjourned_period.days.ago.to_date

    Project.with_route.with_deleting_user.aimed_for_deletion(deletion_cutoff).find_each(batch_size: 100).with_index do |project, index| # rubocop: disable CodeReuse/ActiveRecord -- existing class moved from EE to CE
      delay = index * INTERVAL

      with_context(project: project, user: project.deleting_user) do
        AdjournedProjectDeletionWorker.perform_in(delay, project.id)
      end
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
# rubocop:enable Gitlab/BoundedContexts
# rubocop:enable Gitlab/NamespacedClass
