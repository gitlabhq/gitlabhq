# frozen_string_literal: true

module Issuables
  module GroupMembersFilterable
    include Gitlab::Utils::StrongMemoize

    TooManyGroupMembersError = Class.new(StandardError)
    TooManyAssignedIssuesError = Class.new(StandardError)

    MAX_GROUP_MEMBERS_COUNT = 100
    MAX_ASSIGNED_ISSUES_COUNT = 10_000

    # Returns active record relation if search parameter is a group handle, eg '@group/subgroup'
    def extract_group_member_ids(username_param)
      filter_param = Array(username_param)
      return unless username_param_is_a_group_handle?(filter_param)

      reference_extractor = ::Gitlab::ReferenceExtractor.new(nil, current_user)
      reference_extractor.analyze(filter_param.first, { skip_project_check: true })

      # Extract references when group is readable by user
      group = reference_extractor.references(:mentioned_group).first # rubocop: disable CodeReuse/ActiveRecord -- not an ActiveRecord model
      return unless group

      # Limit the filtering only for groups with less than 100 members
      # to avoid database performance issues
      if group.group_members.limit(MAX_GROUP_MEMBERS_COUNT + 1).count > MAX_GROUP_MEMBERS_COUNT
        raise TooManyGroupMembersError,
          "Group has too many members (limit is #{MAX_GROUP_MEMBERS_COUNT})."
      end

      user_ids = group.group_members.select(:user_id)

      assigned_issues_count = IssueAssignee.where(user_id: user_ids).limit(MAX_ASSIGNED_ISSUES_COUNT + 1).count # rubocop: disable CodeReuse/ActiveRecord -- not an ActiveRecord model
      if assigned_issues_count > MAX_ASSIGNED_ISSUES_COUNT
        raise TooManyAssignedIssuesError,
          "Group has too many assigned issues (limit is #{MAX_ASSIGNED_ISSUES_COUNT})."
      end

      user_ids
    end

    def username_param_is_a_group_handle?(username_param)
      return false if username_param.empty?

      # Only recognize group handle parameter when there is a single username
      # and the username is a group handle. It prevents expensive queries
      # if an user specify multiple groups with 100 members.
      return false if username_param.length > 1

      Group.reference_pattern.match?(username_param.first)
    end
  end
end
