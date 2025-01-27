# frozen_string_literal: true

module Ci
  class BuildTag < Ci::ApplicationRecord
    include Ci::Partitionable
    include BulkInsertSafe

    self.table_name = :p_ci_build_tags
    self.primary_key = :id

    query_constraints :build_id, :partition_id
    partitionable scope: :build, partitioned: true

    belongs_to :build, ->(build_tag) { in_partition(build_tag) }, # rubocop:disable Rails/InverseOf -- Will be added once association on build is added
      class_name: 'Ci::Build', partition_foreign_key: :partition_id, optional: false
    belongs_to :tag, class_name: 'Ci::Tag', optional: false

    validates :project_id, presence: true

    scope :scoped_builds, -> do
      where(arel_table[:build_id].eq(Ci::Build.arel_table[Ci::Build.primary_key]))
        .where(arel_table[:partition_id].eq(Ci::Build.arel_table[:partition_id]))
    end

    scope :scoped_taggables, -> { scoped_builds }
  end
end
