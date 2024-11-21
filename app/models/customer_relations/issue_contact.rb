# frozen_string_literal: true

class CustomerRelations::IssueContact < ApplicationRecord
  include EachBatch

  self.table_name = "issue_customer_relations_contacts"

  belongs_to :issue, optional: false, inverse_of: :customer_relations_contacts
  belongs_to :contact, optional: false, inverse_of: :issue_contacts

  validate :contact_belongs_to_crm_group

  BATCH_DELETE_SIZE = 1_000

  def self.find_contact_ids_by_emails(issue_id, emails)
    raise ArgumentError, "Cannot lookup more than #{MAX_PLUCK} emails" if emails.length > MAX_PLUCK

    joins(:contact)
      .where(issue_id: issue_id, customer_relations_contacts: { email: emails })
      .pluck(:contact_id)
  end

  def self.delete_for_project(project_id)
    loop do
      deleted_records = joins(:issue).where(issues: { project_id: project_id }).limit(BATCH_DELETE_SIZE).delete_all
      break if deleted_records == 0
    end
  end

  def self.delete_for_group(group)
    loop do
      deleted_records = joins(issue: :project).where(projects: { namespace: group.self_and_descendants }).limit(BATCH_DELETE_SIZE).delete_all
      break if deleted_records == 0
    end
  end

  private

  def contact_belongs_to_crm_group
    return unless contact&.group_id
    return if issue&.resource_parent&.crm_group&.id == contact.group_id

    errors.add(:base, _("The contact does not belong to the issue group's CRM source group"))
  end
end
