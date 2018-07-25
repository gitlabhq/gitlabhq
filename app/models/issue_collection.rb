# frozen_string_literal: true

# IssueCollection can be used to reduce a list of issues down to a subset.
#
# IssueCollection is not meant to be some sort of Enumerable, instead it's meant
# to take a list of issues and return a new list of issues based on some
# criteria. For example, given a list of issues you may want to return a list of
# issues that can be read or updated by a given user.
class IssueCollection
  attr_reader :collection

  def initialize(collection)
    @collection = collection
  end

  # Returns all the issues that can be updated by the user.
  def updatable_by_user(user)
    return collection if user.admin?

    # Given all the issue projects we get a list of projects that the current
    # user has at least reporter access to.
    projects_with_reporter_access = user
      .projects_with_reporter_access_limited_to(project_ids)
      .pluck(:id)

    collection.select do |issue|
      if projects_with_reporter_access.include?(issue.project_id)
        true
      elsif issue.is_a?(Issue)
        issue.assignee_or_author?(user)
      else
        false
      end
    end
  end

  alias_method :visible_to, :updatable_by_user

  private

  def project_ids
    @project_ids ||= collection.map(&:project_id).uniq
  end
end
