# frozen_string_literal: true

module CycleAnalytics
  module LevelBase
    STAGES = %i[issue plan code test review staging].freeze

    # This is a temporary adapter class which makes the new value stream (cycle analytics)
    # backend compatible with the old implementation.
    class StageAdapter
      def initialize(stage, options)
        @stage = stage
        @options = options
      end

      # rubocop: disable CodeReuse/Presenter
      def as_json(serializer: AnalyticsStageSerializer)
        presenter = Analytics::CycleAnalytics::StagePresenter.new(stage)

        serializer.new.represent(OpenStruct.new(
                                   title: presenter.title,
                                   description: presenter.description,
                                   legend: presenter.legend,
                                   name: stage.name,
                                   project_median: median,
                                   group_median: median
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
      alias_method :group_median, :median

      private

      attr_reader :stage, :options

      def data_collector
        @data_collector ||= Gitlab::Analytics::CycleAnalytics::DataCollector.new(stage: stage, params: options)
      end
    end

    def all_medians_by_stage
      STAGES.each_with_object({}) do |stage_name, medians_per_stage|
        medians_per_stage[stage_name] = self[stage_name].median
      end
    end

    def stats
      @stats ||= STAGES.map do |stage_name|
        self[stage_name].as_json
      end
    end

    def [](stage_name)
      if Feature.enabled?(:new_project_level_vsa_backend, resource_parent, default_enabled: true)
        StageAdapter.new(build_stage(stage_name), options)
      else
        Gitlab::CycleAnalytics::Stage[stage_name].new(options: options)
      end
    end

    def stage_params_by_name(name)
      Gitlab::Analytics::CycleAnalytics::DefaultStages.find_by_name!(name)
    end
  end
end
