module DevOpsScore
  class Metric < ActiveRecord::Base
    include Presentable

    self.table_name = 'dev_ops_score_metrics'

    def instance_score(feature)
      self["instance_#{feature}"]
    end

    def leader_score(feature)
      self["leader_#{feature}"]
    end

    def percentage_score(feature)
      self["percentage_#{feature}"]
    end
  end
end
