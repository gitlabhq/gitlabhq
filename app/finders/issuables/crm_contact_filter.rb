# frozen_string_literal: true

module Issuables
  class CrmContactFilter < BaseFilter
    def filter(issuables)
      by_crm_contact(issuables)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def by_crm_contact(issuables)
      return issuables if params[:crm_contact_id].blank?
      return issuables unless current_user&.can?(:read_crm_contact, parent&.crm_group)

      condition = CustomerRelations::IssueContact
        .where(contact_id: params[:crm_contact_id])
        .where(Arel.sql("issue_id = issues.id"))
      issuables.where(condition.arel.exists)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
