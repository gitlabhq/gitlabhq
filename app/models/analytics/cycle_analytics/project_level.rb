# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ProjectLevel
      attr_reader :project, :options

      def initialize(project:, options:)
        @project = project
        @options = options.merge(project: project)
      end

      def summary
        @summary ||= ::Gitlab::CycleAnalytics::StageSummary.new(project,
                                                                options: options,
                                                                current_user: options[:current_user]).data
      end

      def permissions(user:)
        Gitlab::CycleAnalytics::Permissions.get(user: user, project: project)
      end

      def stats
        @stats ||= default_stage_names.map do |stage_name|
          self[stage_name].as_json
        end
      end

      def [](stage_name)
        ::CycleAnalytics::ProjectLevelStageAdapter.new(build_stage(stage_name), options)
      end

      private

      def build_stage(stage_name)
        stage_params = stage_params_by_name(stage_name).merge(project: project)
        Analytics::CycleAnalytics::ProjectStage.new(stage_params)
      end

      def stage_params_by_name(name)
        Gitlab::Analytics::CycleAnalytics::DefaultStages.find_by_name!(name)
      end

      def default_stage_names
        Gitlab::Analytics::CycleAnalytics::DefaultStages.symbolized_stage_names
      end
    end
  end
end
Analytics::CycleAnalytics::ProjectLevel.prepend_mod_with('Analytics::CycleAnalytics::ProjectLevel')
