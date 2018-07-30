# frozen_string_literal: true

module Autocomplete
  class ProjectInvitedGroupsFinder
    attr_reader :current_user, :params

    # current_user - The User object of the user that wants to view the list of
    #                projects.
    #
    # params - A Hash containing additional parameters to set.
    #
    # The supported parameters are those supported by
    # `Autocomplete::ProjectFinder`.
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      project = ::Autocomplete::ProjectFinder
        .new(current_user, params)
        .execute

      project ? project.invited_groups : Group.none
    end
  end
end
