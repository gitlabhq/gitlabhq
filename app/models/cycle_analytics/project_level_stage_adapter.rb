# frozen_string_literal: true

# This adapter class makes the new value stream (cycle analytics) backend
# compatible with the old value stream controller actions.
module CycleAnalytics
  class ProjectLevelStageAdapter
    ProjectLevelStage = Struct.new(:title, :description, :legend, :name, :project_median, keyword_init: true )

    def initialize(stage, options)
      @stage = stage
      @options = options
    end

    # rubocop: disable CodeReuse/Presenter
    def as_json(serializer: AnalyticsStageSerializer)
      presenter = Analytics::CycleAnalytics::StagePresenter.new(stage)

      serializer.new.represent(ProjectLevelStage.new(
                                 title: presenter.title,
                                 description: presenter.description,
                                 legend: presenter.legend,
                                 name: stage.name,
                                 project_median: median
                               ))
    end
    # rubocop: enable CodeReuse/Presenter

    def events
      data_collector.records_fetcher.serialized_records
    end

    def median
      data_collector.median.seconds
    end

    alias_method :project_median, :median

    private

    attr_reader :stage, :options

    def data_collector
      @data_collector ||= Gitlab::Analytics::CycleAnalytics::DataCollector.new(stage: stage, params: options)
    end
  end
end
