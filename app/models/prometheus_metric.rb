class PrometheusMetric < ActiveRecord::Base
  belongs_to :project, required: true, validate: true

  validates :title, presence: true
  validates :query, presence: true
end
