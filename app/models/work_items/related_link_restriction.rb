# frozen_string_literal: true

module WorkItems
  class RelatedLinkRestriction < ApplicationRecord
    self.table_name = 'work_item_related_link_restrictions'

    belongs_to :source_type, class_name: 'WorkItems::Type'
    belongs_to :target_type, class_name: 'WorkItems::Type'

    validates :source_type, presence: true
    validates :target_type, presence: true
    validates :target_type, uniqueness: { scope: [:source_type_id, :link_type] }

    enum link_type: Enums::IssuableLink.link_types
  end
end
