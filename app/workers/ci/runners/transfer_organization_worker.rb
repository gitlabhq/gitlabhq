# frozen_string_literal: true

module Ci
  module Runners
    class TransferOrganizationWorker
      include ApplicationWorker

      data_consistency :sticky
      deduplicate :until_executed
      idempotent!
      feature_category :runner_core
      urgency :low
      loggable_arguments 0, 1, 2

      defer_on_database_health_signal :gitlab_ci, [:ci_runners, :ci_runner_machines, :ci_runner_taggings], 1.minute

      def perform(group_id, old_organization_id, new_organization_id)
        result = ::Organizations::Transfer::CiRunnersService.new(
          group: ::Group.find_by_id(group_id),
          old_organization: ::Organizations::Organization.find_by_id(old_organization_id),
          new_organization: ::Organizations::Organization.find_by_id(new_organization_id)
        ).execute

        log_extra_metadata_on_done(:status, result.status)
        log_extra_metadata_on_done(:reason, result.reason) if result.error?
      end
    end
  end
end
