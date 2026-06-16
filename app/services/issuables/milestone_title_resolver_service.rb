# frozen_string_literal: true

module Issuables
  # Resolves a milestone by exact title within a container's scope, matching
  # the behavior of the `/milestone %"X"` quick action: searches project
  # milestones plus all ancestor group milestones (when the container is a
  # project), or the group plus its ancestors (when the container is a group).
  #
  # Returns the matching `Milestone` or `nil` when no milestone with that
  # exact title exists in scope. Title matching is case-sensitive and
  # whitespace-trimmed, mirroring the quick action's `parse_params` block in
  # `Gitlab::QuickActions::IssueAndMergeRequestActions`.
  class MilestoneTitleResolverService
    def initialize(container:, title:)
      @container = container
      @title = title&.strip
    end

    def execute
      return if @title.blank?

      project_ids, group_ids = scope_ids
      return if project_ids.blank? && group_ids.blank?

      MilestonesFinder.new(
        project_ids: project_ids,
        group_ids: group_ids,
        title: @title
      ).execute.first
    end

    private

    def scope_ids
      case @container
      when Project
        [[@container.id], @container.group&.self_and_ancestors&.select(:id)]
      when Group
        [nil, @container.self_and_ancestors.select(:id)]
      end
    end
  end
end
