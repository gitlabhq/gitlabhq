# frozen_string_literal: true

module Resolvers
  module MergeRequests
    class LinkedWorkItemsResolver < BaseResolver
      type [Types::MergeRequests::LinkedWorkItemType], null: true

      CLOSES = Types::MergeRequests::WorkItemLinkTypeEnum.enum[:closes]
      MENTIONED = Types::MergeRequests::WorkItemLinkTypeEnum.enum[:mentioned]
      MAX_ISSUES = 500

      argument :types, [Types::MergeRequests::WorkItemLinkTypeEnum],
        required: false,
        description: 'Filter by link types. Returns all types if not specified.'

      def resolve(types: nil)
        types = [CLOSES, MENTIONED] if types.blank?

        items = []
        items.concat(closing_items) if types.include?(CLOSES)
        items.concat(mentioned_items) if types.include?(MENTIONED)

        # Cap total results to prevent abuse. Each source (closing/mentioned) is independently
        # limited to MAX_ISSUES, but combined they could reach 2x that number.
        items.first(MAX_ISSUES)
      end

      private

      def closing_items
        closing_issues = object.visible_closing_issues_for(current_user).first(MAX_ISSUES)
        linked_work_items_for(closing_issues, CLOSES)
      end

      def mentioned_items
        mentioned_issues = object.issues_mentioned_but_not_closing(current_user).first(MAX_ISSUES)
        linked_work_items_for(mentioned_issues, MENTIONED)
      end

      def linked_work_items_for(issues, link_type)
        issues.filter_map do |issue|
          is_issue = issue.is_a?(Issue)

          ::MergeRequests::LinkedWorkItem.new(
            work_item: is_issue ? issue : nil,
            external_issue: !is_issue ? issue : nil,
            link_type: link_type
          )
        end
      end
    end
  end
end
