# frozen_string_literal: true

module Issuables
  class AuthorFilter < BaseFilter
    include Gitlab::Utils::StrongMemoize

    TooManyGroupMembersError = Class.new(StandardError)

    MAX_GROUP_MEMBERS_COUNT = 100

    def filter(issuables)
      filtered = by_author(issuables)
      filtered = by_author_union(filtered)
      by_negated_author(filtered)
    end

    private

    # Returns an User object if 'author_username' passed is a regular username, eg 'root'
    # Returns active record relation if 'author_username' parameter is a group handle, eg '@group/subgroup'
    def parsed_author_usernames_param
      return User.by_username(params[:author_username]) unless author_param_is_a_group_handle?

      parse_group_handle_to_user_ids
    end
    strong_memoize_attr :parsed_author_usernames_param

    def author_param_is_a_group_handle?
      return false if params[:author_username].is_a?(Array)

      Group.reference_pattern.match?(params[:author_username])
    end

    def parse_group_handle_to_user_ids
      reference_extractor = ::Gitlab::ReferenceExtractor.new(nil, current_user)
      reference_extractor.analyze(params[:author_username], { skip_project_check: true })

      # Extract references when group is readable by user
      group = reference_extractor.references(:mentioned_group).first # rubocop: disable CodeReuse/ActiveRecord -- not an ActiveRecord model
      return unless group

      # Limit the filtering only for groups with less than 100 members
      # to avoid database performance issues
      if group.group_members.count > MAX_GROUP_MEMBERS_COUNT
        raise TooManyGroupMembersError,
          "Group has too many members (limit is #{MAX_GROUP_MEMBERS_COUNT})."
      end

      group.group_members.select(:user_id)
    end

    def by_author(issuables)
      if params[:author_id].present?
        issuables.authored(params[:author_id])
      elsif params[:author_username].present?
        issuables.authored(parsed_author_usernames_param)
          .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/419221")
      else
        issuables
      end
    end

    def by_author_union(issuables)
      return issuables unless or_params&.fetch(:author_username, false).present?

      issuables.authored(User.by_username(or_params[:author_username]))
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/419221")
    end

    def by_negated_author(issuables)
      return issuables unless not_params.present?

      if not_params[:author_id].present?
        issuables.not_authored(not_params[:author_id])
      elsif not_params[:author_username].present?
        issuables.not_authored(User.by_username(not_params[:author_username]))
          .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/419221")
      else
        issuables
      end
    end
  end
end
