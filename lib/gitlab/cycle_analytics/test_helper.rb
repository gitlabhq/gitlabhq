# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module TestHelper
      def stage_query(project_ids)
        if branch
          super(project_ids).where(build_table[:ref].eq(branch))
        else
          super(project_ids)
        end
      end

      private

      def branch
        @branch ||= options[:branch]
      end
    end
  end
end
