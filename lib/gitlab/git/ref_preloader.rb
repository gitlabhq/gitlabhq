# frozen_string_literal: true

module Gitlab
  module Git
    # Collects and batches Git reference existence checks to reduce Gitaly calls.
    #
    # Instead of making individual Gitaly calls for each branch/tag existence check,
    # this module collects refs during request processing and batches them into
    # a single Gitaly call per project.
    #
    # Usage:
    #   RefPreloader.collect_ref(project_id, "refs/heads/main")
    #   RefPreloader.preload_refs_for_project(project)
    module RefPreloader
      # Collects a ref for later batch processing
      def self.collect_ref(project_id, ref_name)
        refs_to_preload[project_id] ||= Set.new
        refs_to_preload[project_id] << ref_name
      end

      # Populates batch loading of all collected refs for the given project
      def self.preload_refs_for_project(project)
        return unless project
        return unless refs_to_preload.key?(project.id)

        refs_to_preload[project.id].each do |ref_name|
          project.repository.lazy_ref_exists?(ref_name)
        end
      end

      # Thread-local storage for refs pending batch processing
      def self.refs_to_preload
        if Gitlab::SafeRequestStore.active?
          Gitlab::SafeRequestStore.fetch(:refs_to_preload) { {} }
        else
          # Needed for tests. SafeRequestStore is disabled by default in the test environment.
          # We would need to modify dozens of tests enabling :request_store before else block can be removed.
          Thread.current[:refs_to_preload] ||= {}
        end
      end
    end
  end
end
