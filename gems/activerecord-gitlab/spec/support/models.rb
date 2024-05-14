# frozen_string_literal: true

class PartitionedRecord < ActiveRecord::Base
  self.abstract_class = true

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

  has_many :unpartitioned_jobs,
    ->(pipeline) { where(pipeline: pipeline).order(id: :desc) },
    partition_foreign_key: :partition_id,
    dependent: :destroy,
    class_name: 'Job'
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

  has_one :test_metadata,
    ->(build) { where(partition_id: build.partition_id, test_flag: true) },
    foreign_key: :job_id,
    partition_foreign_key: :partition_id,
    inverse_of: :job,
    class_name: 'Metadata'

  accepts_nested_attributes_for :metadata
end

class Metadata < PartitionedRecord
  self.table_name = :metadata
  query_constraints :id, :partition_id

  belongs_to :job,
    ->(metadata) { where(partition_id: metadata.partition_id) }
end

class LockingJob < PartitionedRecord
  self.table_name = :locking_jobs
  query_constraints :id, :partition_id

  enum status: { created: 0, completed: 1 }

  def locking_enabled?
    will_save_change_to_status?
  end
end
