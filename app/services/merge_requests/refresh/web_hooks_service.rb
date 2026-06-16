# frozen_string_literal: true

module MergeRequests
  module Refresh
    class WebHooksService < MergeRequests::Refresh::BaseService
      attr_reader :push

      def execute(oldrev, newrev, ref)
        @push = Gitlab::Git::Push.new(@project, oldrev, newrev, ref)

        execute_web_hooks
      end

      private

      def execute_web_hooks
        merge_requests_for_source_branch.each do |mr|
          execute_hooks(mr, 'update', old_rev: @push.oldrev)
        end
      end

      def merge_requests_for(source_branch, mr_states: [:opened])
        super.tap do |mrs|
          ActiveRecord::Associations::Preloader.new(records: mrs, associations: [:metrics]).call
        end
      end
    end
  end
end
