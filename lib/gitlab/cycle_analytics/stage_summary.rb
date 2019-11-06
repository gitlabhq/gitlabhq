# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class StageSummary
      def initialize(project, from:, current_user:)
        @project = project
        @from = from
        @current_user = current_user
      end

      def data
        summary = [issue_stats]
        summary << commit_stats if user_has_sufficient_access?
        summary << deploy_stats
      end

      private

      def issue_stats
        serialize(Summary::Issue.new(project: @project, from: @from, current_user: @current_user))
      end

      def commit_stats
        serialize(Summary::Commit.new(project: @project, from: @from))
      end

      def deploy_stats
        serialize(Summary::Deploy.new(project: @project, from: @from))
      end

      def user_has_sufficient_access?
        @project.team.member?(@current_user, Gitlab::Access::REPORTER)
      end

      def serialize(summary_object)
        AnalyticsSummarySerializer.new.represent(summary_object)
      end
    end
  end
end
