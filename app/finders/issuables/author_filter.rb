# frozen_string_literal: true

module Issuables
  class AuthorFilter < BaseFilter
    include GroupMembersFilterable

    def filter(issuables)
      filtered = by_author(issuables)
      filtered = by_author_union(filtered)
      by_negated_author(filtered)
    end

    private

    def by_author(issuables)
      if params[:author_id].present?
        issuables.authored(params[:author_id])
      elsif params[:author_username].present?
        filter_param =
          extract_group_member_ids(params[:author_username]) || User.by_username(params[:author_username])

        issuables.authored(filter_param)
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
