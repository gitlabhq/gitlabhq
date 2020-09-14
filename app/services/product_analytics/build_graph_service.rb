# frozen_string_literal: true

module ProductAnalytics
  class BuildGraphService
    def initialize(project, params)
      @project = project
      @params = params
    end

    def execute
      graph = @params[:graph].to_sym
      timerange = @params[:timerange].days

      results = product_analytics_events.count_by_graph(graph, timerange)

      format_results(graph, results)
    end

    private

    def format_results(name, results)
      {
        id: name,
        keys: results.keys,
        values: results.values
      }
    end

    def product_analytics_events
      @project.product_analytics_events
    end
  end
end
