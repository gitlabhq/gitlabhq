# frozen_string_literal: true

module DevOpsScore
  class Card
    attr_accessor :metric, :title, :description, :feature, :blog, :docs

    def initialize(metric:, title:, description:, feature:, blog:, docs: nil)
      self.metric = metric
      self.title = title
      self.description = description
      self.feature = feature
      self.blog = blog
      self.docs = docs
    end

    def instance_score
      metric.instance_score(feature)
    end

    def leader_score
      metric.leader_score(feature)
    end

    def percentage_score
      metric.percentage_score(feature)
    end
  end
end
