# frozen_string_literal: true

module MergeRequests
  class AuthorFilter < ::Issuables::AuthorFilter
    private

    def by_author(issuables)
      return super unless params[:include_assigned]

      issuables.author_or_assignee(params[:author_id], params.review_state)
    end
  end
end
