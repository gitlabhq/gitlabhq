# frozen_string_literal: true

module Ci
  class BuildTag < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_build_tags

    query_constraints :build_id, :partition_id
    partitionable scope: :build, partitioned: true

    belongs_to :build, ->(build_tag) { in_partition(build_tag) }, # rubocop:disable Rails/InverseOf -- Will be added once association on build is added
      class_name: 'Ci::Build', partition_foreign_key: :partition_id, optional: false
    belongs_to :tag, class_name: 'Ci::Tag', optional: false

    validates :project_id, presence: true
  end
end
