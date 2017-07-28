module ConversationalDevelopmentIndex
  class Metric < ActiveRecord::Base
    include Presentable

    self.table_name = 'conversational_development_index_metrics'

    def instance_score(feature)
      self["instance_#{feature}"]
    end

    def leader_score(feature)
      self["leader_#{feature}"]
    end

    def percentage_score(feature)
      return self["percentage_#{feature}"] if self["percentage_#{feature}"]

      return 100 if leader_score(feature).zero?

      100 * instance_score(feature) / leader_score(feature)
    end
  end
end
