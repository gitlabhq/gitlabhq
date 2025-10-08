# frozen_string_literal: true

module MergeRequests
  module Refresh
    class PipelineService < MergeRequests::Refresh::BaseService
      attr_reader :push

      def execute(oldrev, newrev, ref)
        @push = Gitlab::Git::Push.new(@project, oldrev, newrev, ref)

        refresh_pipelines unless @push.branch_removed?
      end

      private

      def refresh_pipelines
        merge_requests_for_source_branch.each do |mr|
          refresh_pipelines_on_merge_requests(mr)
        end
      end
    end
  end
end
