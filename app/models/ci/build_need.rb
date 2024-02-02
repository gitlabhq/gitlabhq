# frozen_string_literal: true

module Ci
  class BuildNeed < Ci::ApplicationRecord
    include Ci::Partitionable
    include BulkInsertSafe

    MAX_JOB_NAME_LENGTH = 255

    belongs_to :build,
      ->(need) { in_partition(need) },
      class_name: 'Ci::Processable',
      foreign_key: :build_id,
      partition_foreign_key: :partition_id,
      inverse_of: :needs

    partitionable scope: :build

    validates :build, presence: true
    validates :name, presence: true, length: { maximum: MAX_JOB_NAME_LENGTH }
    validates :optional, inclusion: { in: [true, false] }

    scope :scoped_build, -> {
      where(arel_table[:build_id].eq(Ci::Build.arel_table[:id]))
      .where(arel_table[:partition_id].eq(Ci::Build.arel_table[:partition_id]))
    }
    scope :artifacts, -> { where(artifacts: true) }
  end
end
