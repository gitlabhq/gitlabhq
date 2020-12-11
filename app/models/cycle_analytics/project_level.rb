# frozen_string_literal: true

module CycleAnalytics
  class ProjectLevel
    include LevelBase
    attr_reader :project, :options

    def initialize(project, options:)
      @project = project
      @options = options.merge(project: project)
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::StageSummary.new(project,
                                                              from: options[:from],
                                                              to: options[:to],
                                                              current_user: options[:current_user]).data
    end

    def permissions(user:)
      Gitlab::CycleAnalytics::Permissions.get(user: user, project: project)
    end

    def build_stage(stage_name)
      stage_params = stage_params_by_name(stage_name).merge(project: project)
      Analytics::CycleAnalytics::ProjectStage.new(stage_params)
    end

    def resource_parent
      project
    end
  end
end
