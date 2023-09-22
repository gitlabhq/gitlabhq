# frozen_string_literal: true

module WorkItems
  class RelatedWorkItemLink < ApplicationRecord
    include LinkableItem

    self.table_name = 'issue_links'

    MAX_LINKS_COUNT = 100

    belongs_to :source, class_name: 'WorkItem'
    belongs_to :target, class_name: 'WorkItem'

    class << self
      extend ::Gitlab::Utils::Override

      # Used as issuable table name for calculating blocked and blocking count in IssuableLink
      override :issuable_type
      def issuable_type
        :issue
      end

      override :issuable_name
      def issuable_name
        'work item'
      end
    end
  end
end
