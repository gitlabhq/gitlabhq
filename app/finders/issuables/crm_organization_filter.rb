# frozen_string_literal: true

module Issuables
  class CrmOrganizationFilter < BaseFilter
    def filter(issuables)
      by_crm_organization(issuables)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def by_crm_organization(issuables)
      return issuables if params[:crm_organization_id].blank?

      condition = CustomerRelations::IssueContact
        .joins(:contact)
        .where(contact: { organization_id: params[:crm_organization_id] })
        .where(Arel.sql("issue_id = issues.id"))
      issuables.where(condition.arel.exists)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
