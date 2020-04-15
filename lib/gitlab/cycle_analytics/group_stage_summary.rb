# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class GroupStageSummary
      attr_reader :group, :current_user, :options

      def initialize(group, options:)
        @group = group
        @current_user = options[:current_user]
        @options = options
      end

      def data
        [issue_stats,
         deploy_stats,
         deployment_frequency_stats]
      end

      private

      def issue_stats
        serialize(
          Summary::Group::Issue.new(
            group: group, current_user: current_user, options: options)
        )
      end

      def deployments_summary
        @deployments_summary ||=
          Summary::Group::Deploy.new(group: group, options: options)
      end

      def deploy_stats
        serialize deployments_summary
      end

      def deployment_frequency_stats
        serialize(
          Summary::Group::DeploymentFrequency.new(
            deployments: deployments_summary.value,
            group: group,
            options: options),
          with_unit: true
        )
      end

      def serialize(summary_object, with_unit: false)
        AnalyticsSummarySerializer.new.represent(
          summary_object, with_unit: with_unit)
      end
    end
  end
end
