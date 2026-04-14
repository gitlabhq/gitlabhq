# frozen_string_literal: true

module Gitlab
  module Repositories
    class RefCacheUpdateService
      def initialize(repository, changes)
        @repository = repository
        @changes = changes
      end

      def execute
        return unless repository.project
        return unless Feature.enabled?(:ref_cache_with_rebuild_queue, repository.project)

        process_changes(changes.branch_changes) if changes.includes_branches?
        process_changes(changes.tag_changes) if changes.includes_tags?
      end

      private

      attr_reader :repository, :changes

      def process_changes(ref_changes)
        ref_changes.each do |change|
          repository.incremental_ref_cache_update(change[:ref], Gitlab::Git.blank_ref?(change[:newrev]))
        end
      end
    end
  end
end
