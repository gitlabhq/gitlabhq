# frozen_string_literal: true

module WorkItems
  class RelatedWorkItemLink < ApplicationRecord
    include LinkableItem

    self.table_name = 'issue_links'

    MAX_LINKS_COUNT = 100

    belongs_to :source, class_name: 'WorkItem'
    belongs_to :target, class_name: 'WorkItem'

    validate :validate_related_link_restrictions

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

    private

    def validate_related_link_restrictions
      return unless source && target

      source_type = source.work_item_type
      target_type = target.work_item_type

      return if link_restriction_exists?(source_type.id, target_type.id)

      errors.add :source, format(
        s_('%{source_type} cannot be related to %{type_type}'),
        source_type: source_type.name.downcase.pluralize,
        type_type: target_type.name.downcase.pluralize
      )
    end

    def link_restriction_exists?(source_type_id, target_type_id)
      source_restriction = find_restriction(source_type_id, target_type_id)
      return true if source_restriction.present?
      return false if source_type_id == target_type_id

      find_restriction(target_type_id, source_type_id).present?
    end

    def find_restriction(source_type_id, target_type_id)
      ::WorkItems::RelatedLinkRestriction.find_by_source_type_id_and_target_type_id_and_link_type(
        source_type_id,
        target_type_id,
        link_type
      )
    end
  end
end

WorkItems::RelatedWorkItemLink.prepend_mod
