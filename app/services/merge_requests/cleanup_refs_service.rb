# frozen_string_literal: true

module MergeRequests
  class CleanupRefsService
    include BaseServiceUtility

    TIME_THRESHOLD = 14.days

    attr_reader :merge_request

    def self.schedule(merge_request)
      MergeRequestCleanupRefsWorker.perform_in(TIME_THRESHOLD, merge_request.id)
    end

    def initialize(merge_request)
      @merge_request = merge_request
      @repository = merge_request.project.repository
      @ref_path = merge_request.ref_path
      @ref_head_sha = @repository.commit(merge_request.ref_path).id
    end

    def execute
      return error("Merge request has not been closed nor merged for #{TIME_THRESHOLD.inspect}.") unless eligible?

      # Ensure that commit shas of refs are kept around so we won't lose them when GC runs.
      keep_around

      return error('Failed to create keep around refs.') unless kept_around?

      delete_refs
      success
    end

    private

    attr_reader :repository, :ref_path, :ref_head_sha

    def eligible?
      return met_time_threshold?(merge_request.metrics&.latest_closed_at) if merge_request.closed?

      merge_request.merged? && met_time_threshold?(merge_request.metrics&.merged_at)
    end

    def met_time_threshold?(attr)
      attr.nil? || attr.to_i <= TIME_THRESHOLD.ago.to_i
    end

    def kept_around?
      Gitlab::Git::KeepAround.new(repository).kept_around?(ref_head_sha)
    end

    def keep_around
      repository.keep_around(ref_head_sha)
    end

    def delete_refs
      repository.delete_refs(ref_path)
    end
  end
end
