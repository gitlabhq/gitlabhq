# frozen_string_literal: true

module Gitlab
  module Git
    class RefResolver
      include Gitlab::Utils::StrongMemoize

      def initialize(repository, origin_ref)
        @repository = repository
        @origin_ref = origin_ref
        @ref_name = Gitlab::Git.ref_name(origin_ref) if origin_ref
      end

      def resolved_ref
        if full_branch_or_tag_path?
          @origin_ref if @repository.ref_exists?(@origin_ref)
        elsif merge_request_or_workload_path?
          @origin_ref
        elsif ambiguous?
          nil
        elsif branch_exists?
          Gitlab::Git::BRANCH_REF_PREFIX + @ref_name
        elsif tag_exists?
          Gitlab::Git::TAG_REF_PREFIX + @ref_name
        end
      end
      strong_memoize_attr :resolved_ref

      def ambiguous?
        !full_branch_or_tag_path? && !merge_request_or_workload_path? && branch_exists? && tag_exists?
      end

      def branch?
        !!(resolved_ref && Gitlab::Git.branch_ref?(resolved_ref))
      end

      def tag?
        !!(resolved_ref && Gitlab::Git.tag_ref?(resolved_ref))
      end

      def merge_request?
        !!(resolved_ref && MergeRequest.merge_request_ref?(resolved_ref))
      end

      def workload?
        !!(resolved_ref && ::Ci::Workloads::Workload.workload_ref?(resolved_ref))
      end

      private

      def full_branch_or_tag_path?
        @origin_ref && (Gitlab::Git.branch_ref?(@origin_ref) || Gitlab::Git.tag_ref?(@origin_ref))
      end

      def merge_request_or_workload_path?
        @origin_ref && (MergeRequest.merge_request_ref?(@origin_ref) ||
          ::Ci::Workloads::Workload.workload_ref?(@origin_ref))
      end

      def branch_exists?
        @ref_name && @repository.branch_exists?(@ref_name)
      end
      strong_memoize_attr :branch_exists?

      def tag_exists?
        @ref_name && @repository.tag_exists?(@ref_name)
      end
      strong_memoize_attr :tag_exists?
    end
  end
end
