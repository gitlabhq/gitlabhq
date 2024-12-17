# frozen_string_literal: true

class Ci::BuildPendingState < Ci::ApplicationRecord
  include Ci::Partitionable

  before_validation :set_project_id, on: :create
  belongs_to :build,
    ->(pending_state) { in_partition(pending_state) },
    class_name: 'Ci::Build',
    foreign_key: :build_id,
    partition_foreign_key: :partition_id,
    inverse_of: :pending_state

  partitionable scope: :build

  enum state: Ci::Stage.statuses
  enum failure_reason: CommitStatus.failure_reasons

  validates :build, presence: true
  validates :project_id, presence: true, on: :create

  def crc32
    trace_checksum.try do |checksum|
      checksum.to_s.split('crc32:').last.to_i(16)
    end
  end

  def set_project_id
    self.project_id ||= build&.project_id
  end
end
