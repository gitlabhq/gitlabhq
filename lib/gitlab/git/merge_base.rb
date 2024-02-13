# frozen_string_literal: true

module Gitlab
  module Git
    class MergeBase
      include Gitlab::Utils::StrongMemoize

      def initialize(repository, refs)
        @repository = repository
        @refs = refs
      end

      # Returns the SHA of the first common ancestor
      def sha
        if unknown_refs.any?
          raise ReferenceNotFoundError, "Can't find merge base for unknown refs: #{unknown_refs.inspect}"
        end

        strong_memoize(:sha) do
          @repository.merge_base(*commits_for_refs)
        end
      end

      # Returns the merge base as a Gitlab::Git::Commit
      def commit
        return unless sha

        @commit ||= @repository.commit_by(oid: sha)
      end

      # Returns the refs passed on initialization that aren't found in
      # the repository, and thus cannot be used to find a merge base.
      def unknown_refs
        @unknown_refs ||= Hash[@refs.zip(commits_for_refs)]
                            .select { |ref, commit| commit.nil? }.keys
      end

      private

      def commits_for_refs
        @commits_for_refs ||= @repository.commits_by(oids: @refs)
      end
    end
  end
end
