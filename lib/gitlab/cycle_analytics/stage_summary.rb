# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class StageSummary
      def initialize(project, options:, current_user:)
        @project = project
        @options = options
        @current_user = current_user
      end

      def data
        summary = [issue_stats]
        summary << commit_stats if user_has_sufficient_access?
        summary << deploy_stats
        summary << deployment_frequency_stats
      end

      private

      def issue_stats
        serialize(Summary::Issue.new(project: @project, options: @options, current_user: @current_user))
      end

      def commit_stats
        serialize(Summary::Commit.new(project: @project, options: @options))
      end

      def deployments_summary
        @deployments_summary ||= Summary::Deploy.new(project: @project, options: @options)
      end

      def deploy_stats
        serialize deployments_summary
      end

      def deployment_frequency_stats
        serialize(
          Summary::DeploymentFrequency.new(
            deployments: deployments_summary.value.raw_value,
            options: @options),
          with_unit: true
        )
      end

      def user_has_sufficient_access?
        @project.team.member?(@current_user, Gitlab::Access::REPORTER)
      end

      def serialize(summary_object, with_unit: false)
        AnalyticsSummarySerializer.new.represent(summary_object, with_unit: with_unit)
      end
    end
  end
end
