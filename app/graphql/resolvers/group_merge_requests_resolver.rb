# frozen_string_literal: true

module Resolvers
  class GroupMergeRequestsResolver < MergeRequestsResolver
    def self.issuable_collection_name
      'merge requests'
    end

    include GroupIssuableResolver

    alias_method :group, :object

    type Types::MergeRequestType.connection_type, null: true

    accept_assignee
    accept_reviewer
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
