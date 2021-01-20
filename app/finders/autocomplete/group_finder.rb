# frozen_string_literal: true

module Autocomplete
  # Finder for retrieving a group to use for autocomplete data sources.
  class GroupFinder
    attr_reader :current_user, :project, :group_id

    # current_user - The currently logged in user, if any.
    # project - The Project (if any) to use for the autocomplete data sources.
    # params - A Hash containing parameters to use for finding the project.
    #
    # The following parameters are supported:
    #
    # * group_id: The ID of the group to find.
    def initialize(current_user = nil, project = nil, params = {})
      @current_user = current_user
      @project = project
      @group_id = params[:group_id]
    end

    # Attempts to find a Group based on the current group ID.
    def execute
      return unless project.blank? && group_id.present?

      group = Group.find(group_id)

      # This removes the need for using `return render_404` and similar patterns
      # in controllers that use this finder.
      unless Ability.allowed?(current_user, :read_group, group)
        raise ActiveRecord::RecordNotFound, "Could not find a Group with ID #{group_id}"
      end

      group
    end
  end
end
