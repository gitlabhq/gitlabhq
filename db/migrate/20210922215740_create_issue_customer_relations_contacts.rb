# frozen_string_literal: true

class CreateIssueCustomerRelationsContacts < Gitlab::Database::Migration[1.0]
  def change
    create_table :issue_customer_relations_contacts do |t|
      t.bigint :issue_id, null: false
      t.bigint :contact_id, null: false
      t.timestamps_with_timezone null: false

      t.index :contact_id
      t.index [:issue_id, :contact_id], unique: true, name: :index_issue_crm_contacts_on_issue_id_and_contact_id
    end
  end
end
