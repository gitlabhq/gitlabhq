module ConversationalDevelopmentIndex
  class IdeaToProductionStep
    attr_accessor :metric, :title, :features

    def initialize(metric:, title:, features:)
      self.metric = metric
      self.title = title
      self.features = features
    end

    def percentage_score
      sum = features.map do |feature|
        metric.percentage_score(feature)
      end.inject(:+)

      sum / features.size.to_f
    end
  end
end
