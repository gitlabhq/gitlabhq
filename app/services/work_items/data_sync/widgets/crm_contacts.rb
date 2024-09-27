# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class CrmContacts < Base
        def after_save_commit
          # copy contacts, e.g.
          # return unless work_item.namespace.root_ancestor == target_work_item.namespace.root_ancestor
          #
          # target_work_item.customer_relations_contacts = work_item.customer_relations_contacts
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
