# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      class Permissions < Grape::Entity
        PERMISSION_ABILITIES = %i[
          read_work_item
          update_work_item
          delete_work_item
          admin_work_item
          admin_parent_link
          set_work_item_metadata
          create_note
          admin_work_item_link
          mark_note_as_internal
          report_spam
          move_work_item
          clone_work_item
          summarize_comments
        ].freeze

        PERMISSION_ABILITIES.each do |ability|
          expose ability,
            documentation: { type: 'Boolean', example: true } do |work_item, options|
              Ability.allowed?(options[:current_user], ability, work_item)
            end
        end
      end
    end
  end
end
