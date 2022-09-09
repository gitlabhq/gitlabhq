# frozen_string_literal: true

module MergeRequests
  # Used to filter MergeRequest collections by approvers
  class ByApprovalsFinder
    attr_reader :usernames, :ids

    # We apply a limitation to the amount of elements that can be part of the filter condition
    MAX_FILTER_ELEMENTS = 5

    # Initialize the finder
    #
    # @param [Array<String>] usernames
    # @param [Array<Integers>] ids
    def initialize(usernames, ids)
      # rubocop:disable CodeReuse/ActiveRecord
      @usernames = Array(usernames).map(&:to_s).uniq.take(MAX_FILTER_ELEMENTS)
      @ids = Array(ids).uniq.take(MAX_FILTER_ELEMENTS)
      # rubocop:enable CodeReuse/ActiveRecord
    end

    # Filter MergeRequest collections by approvers
    #
    # @param [ActiveRecord::Relation] items the activerecord relation
    def execute(items)
      if by_no_approvals?
        without_approvals(items)
      elsif by_any_approvals?
        with_any_approvals(items)
      elsif ids.present?
        find_approved_by_ids(items)
      elsif usernames.present?
        find_approved_by_names(items)
      else
        items
      end
    end

    private

    # Is param using special condition: "None" ?
    #
    # @return [Boolean] whether special condition "None" is being used
    def by_no_approvals?
      includes_special_label?(IssuableFinder::Params::FILTER_NONE)
    end

    # Is param using special condition: "Any" ?
    #
    # @return [Boolean] whether special condition "Any" is being used
    def by_any_approvals?
      includes_special_label?(IssuableFinder::Params::FILTER_ANY)
    end

    # Check if we have the special label in ids or usernames field
    #
    # @param [String] label the special label
    # @return [Boolean] whether ids or usernames includes the special label
    def includes_special_label?(label)
      ids.first.to_s.downcase == label || usernames.map(&:downcase).include?(label)
    end

    # Merge requests without any approval
    #
    # @param [ActiveRecord::Relation] items
    def without_approvals(items)
      items.without_approvals
    end

    # Merge requests with any number of approvals
    #
    # @param [ActiveRecord::Relation] items the activerecord relation
    def with_any_approvals(items)
      items.select_from_union([items.with_approvals])
    end

    # Merge requests approved by given usernames
    #
    # @param [ActiveRecord::Relation] items the activerecord relation
    def find_approved_by_names(items)
      items.approved_by_users_with_usernames(*usernames)
    end

    # Merge requests approved by given user IDs
    #
    # @param [ActiveRecord::Relation] items the activerecord relation
    def find_approved_by_ids(items)
      items.approved_by_users_with_ids(*ids)
    end
  end
end
