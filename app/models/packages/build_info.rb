# frozen_string_literal: true

class Packages::BuildInfo < ApplicationRecord
  belongs_to :package, inverse_of: :build_infos
  belongs_to :pipeline, class_name: 'Ci::Pipeline'

  scope :pluck_pipeline_ids, -> { pluck(:pipeline_id) }
  scope :without_empty_pipelines, -> { where.not(pipeline_id: nil) }
  scope :order_by_pipeline_id, ->(direction) { order(pipeline_id: direction) }
  scope :with_pipeline_id_less_than, ->(pipeline_id) { where("#{table_name}.pipeline_id < ?", pipeline_id) }
  scope :with_pipeline_id_greater_than, ->(pipeline_id) { where("#{table_name}.pipeline_id > ?", pipeline_id) }

  def self.supported_keyset_orderings
    { id: [:desc] }
  end
end
