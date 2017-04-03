class CycleAnalytics
  STAGES = %i[issue plan code test review staging production].freeze

  def initialize(project, options)
    @project = project
    @options = options
  end

  def summary
    @summary ||= ::Gitlab::CycleAnalytics::StageSummary.new(@project,
                                                            from: @options[:from],
                                                            current_user: @options[:current_user]).data
  end

  def stats
    @stats ||= stats_per_stage
  end

  def no_stats?
    stats.all? { |hash| hash[:value].nil? }
  end

  def permissions(user:)
    Gitlab::CycleAnalytics::Permissions.get(user: user, project: @project)
  end

  def [](stage_name)
    Gitlab::CycleAnalytics::Stage[stage_name].new(project: @project, options: @options)
  end

  private

  def stats_per_stage
    STAGES.map do |stage_name|
      self[stage_name].as_json
    end
  end
end
