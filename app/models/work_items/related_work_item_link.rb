# frozen_string_literal: true

module WorkItems
  class RelatedWorkItemLink < ApplicationRecord
    include LinkableItem

    self.table_name = 'issue_links'

    belongs_to :source, class_name: 'WorkItem'
    belongs_to :target, class_name: 'WorkItem'

    class << self
      extend ::Gitlab::Utils::Override

      override :issuable_type
      def issuable_type
        :work_item
      end
    end
  end
end
