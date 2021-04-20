# frozen_string_literal: true

module Resolvers
  class GroupMergeRequestsResolver < MergeRequestsResolver
    include GroupIssuableResolver

    alias_method :group, :object

    type Types::MergeRequestType.connection_type, null: true

    include_subgroups 'merge requests'
    accept_assignee
    accept_author

    def project
      nil
    end

    def mr_parent
      group
    end

    def no_results_possible?(args)
      group.nil? || some_argument_is_empty?(args)
    end
  end
end
