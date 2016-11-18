class CycleAnalytics
  STAGES = %i[issue plan code test review staging production].freeze

  def initialize(project, from:)
    @project = project
    @options = options
  end

  def summary
    @summary ||= Summary.new(@project, from: @options[:from])
  end

  def method_missing(method_sym, *arguments, &block)
    classify_stage(method_sym).new(project: @project, options: @options, stage: method_sym)
  def permissions(user:)
    Gitlab::CycleAnalytics::Permissions.get(user: user, project: @project)
  end

  def issue
    @fetcher.calculate_metric(:issue,
                     Issue.arel_table[:created_at],
                     [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                      Issue::Metrics.arel_table[:first_added_to_board_at]])
  end

  def classify_stage(method_sym)
    "Gitlab::CycleAnalytics::#{method_sym.to_s.capitalize}Stage".constantize
  end
end
