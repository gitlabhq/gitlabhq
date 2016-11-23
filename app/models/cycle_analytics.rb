class CycleAnalytics
  STAGES = %i[issue plan code test review staging production].freeze

  def initialize(project, options:)
    @project = project
    @options = options
  end

  def summary
    @summary ||= ::Gitlab::CycleAnalytics::StageSummary.new(@project, from: @options[:from]).data
  end

  def stats
    @stats ||= stats_per_stage
  end

  def no_stats?
    stats.map { |hash| hash[:value] }.compact.empty?
  end

  def permissions(user:)
    Gitlab::CycleAnalytics::Permissions.get(user: user, project: @project)
  end

  def events_for(stage)
    classify_stage(stage).new(project: @project, options: @options, stage: stage).events
  end

  private

  def stats_per_stage
    STAGES.map do |stage_name|
      classify_stage(stage_name).new(project: @project, options: @options, stage: stage_name).median_data
    end
  end

  def classify_stage(stage_name)
    "Gitlab::CycleAnalytics::#{stage_name.to_s.capitalize}Stage".constantize
  end
end
