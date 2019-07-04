# frozen_string_literal: true

module CycleAnalytics
  class ProjectLevel
    include BaseMethods
    attr_reader :project, :options

    def initialize(project, options:)
      @project = project
      @options = options.merge(project: project)
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::StageSummary.new(project,
                                                              from: options[:from],
                                                              current_user: options[:current_user]).data
    end

    def permissions(user:)
      Gitlab::CycleAnalytics::Permissions.get(user: user, project: project)
    end
  end
end
