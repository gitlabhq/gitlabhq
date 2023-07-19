# frozen_string_literal: true

class PartitionedRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.use_partition_id_filter?
    true
  end

  alias_method :reset, :reload
end

class Project < ActiveRecord::Base
  has_many :pipelines
end

class Pipeline < PartitionedRecord
  belongs_to :project
  query_constraints :id, :partition_id

  has_many :jobs,
    ->(pipeline) { where(partition_id: pipeline.partition_id) },
    partition_foreign_key: :partition_id,
    dependent: :destroy
end

class Job < PartitionedRecord
  query_constraints :id, :partition_id

  belongs_to :pipeline,
    ->(build) { where(partition_id: build.partition_id) },
    partition_foreign_key: :partition_id

  has_one :metadata,
    ->(build) { where(partition_id: build.partition_id) },
    foreign_key: :job_id,
    partition_foreign_key: :partition_id,
    inverse_of: :job,
    autosave: true

  accepts_nested_attributes_for :metadata
end

class Metadata < PartitionedRecord
  self.table_name = :metadata
  query_constraints :id, :partition_id

  belongs_to :job,
    ->(metadata) { where(partition_id: metadata.partition_id) }
end
