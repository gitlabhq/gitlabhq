# frozen_string_literal: true

module Organizations
  class TransferUserAgentDetailsWorker
    include ApplicationWorker

    data_consistency :sticky
    deduplicate :until_executed
    idempotent!
    feature_category :instance_resiliency
    urgency :low
    loggable_arguments 0, 1, 2

    defer_on_database_health_signal :gitlab_main, [:user_agent_details, :issues], 1.minute

    # The organizations are passed in rather than read from the group: by the time this runs
    # group.organization_id is the target, so the source is no longer recoverable from the group.
    def perform(group_id, old_organization_id, new_organization_id)
      group = ::Group.find_by_id(group_id)
      unless group
        logger.info(structured_payload(message: 'Group not found.', group_id: group_id))
        return
      end

      old_organization = ::Organizations::Organization.find_by_id(old_organization_id)
      unless old_organization
        logger.info(structured_payload(message: 'Old organization not found.', organization_id: old_organization_id))
        return
      end

      new_organization = ::Organizations::Organization.find_by_id(new_organization_id)
      unless new_organization
        logger.info(structured_payload(message: 'New organization not found.', organization_id: new_organization_id))
        return
      end

      ::Organizations::Transfer::UserAgentDetailsService.new(
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      ).execute
    end
  end
end
