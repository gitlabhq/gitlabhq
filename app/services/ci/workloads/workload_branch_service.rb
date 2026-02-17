# frozen_string_literal: true

module Ci
  module Workloads
    class WorkloadBranchService
      def initialize(project:, source_branch:, current_user:)
        @project = project
        @current_user = current_user
        @source_branch = source_branch
      end

      def execute
        workload_ref = "workloads/#{SecureRandom.hex[0..10]}"
        source_ref = @project.repository.branch_exists?(@source_branch) ? @source_branch : default_branch
        create_internal_refs(source_ref, workload_ref)
      rescue Gitlab::Git::CommandError => e
        Gitlab::ErrorTracking.track_exception(e)
        ServiceResponse.error(message: 'Failed to create workload ref')
      end

      private

      def create_internal_refs(source_ref, workload_ref)
        source_sha = @project.repository.commit(source_ref)&.sha
        return ServiceResponse.error(message: 'Source ref not found') unless source_sha

        workload_ref_path = "refs/#{workload_ref}"
        if @project.repository.ref_exists?(workload_ref_path)
          return ServiceResponse.error(message: 'Ref already exists')
        end

        result = @project.repository.create_ref(source_sha, workload_ref_path)
        return ServiceResponse.error(message: 'Error in git ref creation') unless result

        ServiceResponse.success(payload: { ref: workload_ref_path })
      end

      def default_branch
        @project.default_branch_or_main
      end
    end
  end
end
