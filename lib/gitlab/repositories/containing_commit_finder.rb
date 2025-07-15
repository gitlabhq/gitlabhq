# frozen_string_literal: true

module Gitlab
  module Repositories
    class ContainingCommitFinder
      NO_LIMIT = 0

      def initialize(repository, sha, params = {})
        @repository = repository
        @sha = sha
        @params = params
      end

      def execute
        return all_refs unless has_limit?

        remaining_limit = total_limit

        branches = find_matching_branches(branches_limit: remaining_limit)

        remaining_limit -= branches.size

        return branches if remaining_limit == 0

        branches + find_matching_tags(tags_limit: remaining_limit)
      end

      private

      attr_reader :repository, :sha, :params

      def all_refs
        find_matching_branches + find_matching_tags
      end

      def find_matching_branches(branches_limit: total_limit)
        return [] if tag? || sha.blank?

        repository.branch_names_contains(sha, limit: branches_limit).map { |name| { type: 'branch', name: name } }
      end

      def find_matching_tags(tags_limit: total_limit)
        return [] if branch? || sha.blank?

        repository.tag_names_contains(sha, limit: tags_limit).map { |name| { type: 'tag', name: name } }
      end

      def type
        params[:type]
      end

      def tag?
        type == 'tag'
      end

      def branch?
        type == 'branch'
      end

      def has_limit?
        total_limit > NO_LIMIT
      end

      def total_limit
        params[:limit].presence || NO_LIMIT
      end
    end
  end
end
