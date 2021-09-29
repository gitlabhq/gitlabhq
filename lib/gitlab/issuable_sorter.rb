# frozen_string_literal: true

module Gitlab
  module IssuableSorter
    class << self
      def sort(project, issuables, &sort_key)
        grouped_items = issuables.group_by do |issuable|
          if issuable.project.id == project.id
            :project_ref
          elsif issuable.project.namespace_id == project.namespace_id
            :namespace_ref
          else
            :full_ref
          end
        end

        natural_sort_issuables(grouped_items[:project_ref], project) +
          natural_sort_issuables(grouped_items[:namespace_ref], project) +
          natural_sort_issuables(grouped_items[:full_ref], project)
      end

      private

      def natural_sort_issuables(issuables, project)
        VersionSorter.sort(issuables || []) do |issuable|
          issuable.to_reference(project)
        end
      end
    end
  end
end
