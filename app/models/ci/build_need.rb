# frozen_string_literal: true

module Ci
  class BuildNeed < Ci::ApplicationRecord
    include Ci::Partitionable
    include BulkInsertSafe

    MAX_JOB_NAME_LENGTH = 255

    before_validation :set_project_id, on: :create

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
    validates :project_id, presence: true, on: :create

    scope :scoped_build, -> {
      where(arel_table[:build_id].eq(Ci::Build.arel_table[:id]))
      .where(arel_table[:partition_id].eq(Ci::Build.arel_table[:partition_id]))
    }
    scope :artifacts, -> { where(artifacts: true) }

    # TODO: This is temporary code to assist the backfilling of records for this epic: https://gitlab.com/groups/gitlab-org/-/epics/12323
    # To be removed in 17.7: https://gitlab.com/gitlab-org/gitlab/-/issues/488163
    #
    def set_project_id
      self.project_id ||= build&.project_id
    end
  end
end
