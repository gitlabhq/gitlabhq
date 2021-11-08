# frozen_string_literal: true

class CustomerRelations::IssueContact < ApplicationRecord
  self.table_name = "issue_customer_relations_contacts"

  belongs_to :issue, optional: false, inverse_of: :customer_relations_contacts
  belongs_to :contact, optional: false, inverse_of: :issue_contacts

  validate :contact_belongs_to_issue_group

  private

  def contact_belongs_to_issue_group
    return unless contact&.group_id
    return unless issue&.project&.namespace_id
    return if contact.group_id == issue.project.namespace_id

    errors.add(:base, _('The contact does not belong to the same group as the issue'))
  end
end
