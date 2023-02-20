# frozen_string_literal: true

# Service for calculating visible Snippet counts via one query
# for the given user or project.
#
# Authorisation level checks will be included, ensuring the correct
# counts will be returned for the given user (if any).
#
# Basic usage:
#
#   user = User.find(1)
#
#   Snippets::CountService.new(user, author: user).execute
#   #=> {
#     are_public: 1,
#     are_internal: 1,
#     are_private: 1,
#     all: 3
#   }
#
# Counts can be scoped to a project:
#
#   user = User.find(1)
#   project = Project.find(1)
#
#   Snippets::CountService.new(user, project: project).execute
#   #=> {
#     are_public: 1,
#     are_internal: 1,
#     are_private: 0,
#     all: 2
#   }
#
# Either a project or an author *must* be supplied.
module Snippets
  class CountService
    def initialize(current_user, author: nil, project: nil)
      if !author && !project
        raise(
          ArgumentError, 'Must provide either an author or a project'
        )
      end

      @snippets_finder = SnippetsFinder.new(current_user, author: author, project: project)
    end

    def execute
      counts = snippet_counts
      return {} unless counts

      counts.slice(
        :are_public,
        :are_private,
        :are_internal,
        :are_public_or_internal,
        :total
      )
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def snippet_counts
      @snippets_finder.execute
        .reorder(nil)
        .select("
          count(case when snippets.visibility_level=#{Snippet::PUBLIC} and snippets.secret is FALSE then 1 else null end) as are_public,
          count(case when snippets.visibility_level=#{Snippet::INTERNAL} then 1 else null end) as are_internal,
          count(case when snippets.visibility_level=#{Snippet::PRIVATE} then 1 else null end) as are_private,
          count(case when visibility_level=#{Snippet::PUBLIC} OR visibility_level=#{Snippet::INTERNAL} then 1 else null end) as are_public_or_internal,
          count(*) as total
        ")
        .take
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
