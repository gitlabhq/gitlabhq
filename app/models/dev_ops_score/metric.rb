# frozen_string_literal: true

module DevOpsScore
  class Metric < ApplicationRecord
    include Presentable

    self.table_name = 'conversational_development_index_metrics'

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
