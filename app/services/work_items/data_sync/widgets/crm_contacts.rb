# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class CrmContacts < Base
        def after_save_commit
          return unless target_work_item.get_widget(:crm_contacts)

          if work_item.namespace.crm_group == target_work_item.namespace.crm_group
            work_item.issue_customer_relations_contacts.each_batch(of: BATCH_SIZE) do |issue_contacts_batch|
              CustomerRelations::IssueContact.insert_all(attributes(target_work_item, issue_contacts_batch))
            end
          else
            ::SystemNoteService.change_issuable_contacts(
              target_work_item,
              target_work_item.namespace,
              current_user,
              0, # count of added contacts
              work_item.customer_relations_contacts.count # count of removed contacts
            )
          end
        end

        def post_move_cleanup
          work_item.issue_customer_relations_contacts.each_batch(of: BATCH_SIZE) do |contacts_batch|
            contacts_batch.delete_all
          end
        end

        private

        def attributes(target_work_item, issue_contacts)
          issue_contacts.map do |issue_contact|
            if params[:operation] == :move
              issue_contact.attributes.except("id").tap { |c| c["issue_id"] = target_work_item.id }
            else
              issue_contact.attributes.except("id", "created_at", "updated_at").tap do |c|
                c["issue_id"] = target_work_item.id
              end
            end
          end
        end
      end
    end
  end
end
