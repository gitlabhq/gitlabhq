# frozen_string_literal: true

module Ci
  class JobDefinitionInstance < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_job_definition_instances
    self.primary_key = :job_id

    query_constraints :job_id, :partition_id
    partitionable scope: :job, partitioned: true

    belongs_to :project

    belongs_to :job, ->(job) { in_partition(job) },
      class_name: 'Ci::Processable', partition_foreign_key: :partition_id,
      inverse_of: :job_definition_instance

    belongs_to :job_definition, ->(definition) { in_partition(definition) }, # rubocop: disable Rails/InverseOf -- this relation is not present on Ci::JobDefinition
      class_name: 'Ci::JobDefinition', partition_foreign_key: :partition_id

    validates :project, presence: true
    validates :job, presence: true
    # Validate the foreign key rather than the association: an association
    # presence validation loads the record, which costs a query when only the
    # id is assigned. Row existence is enforced by the composite foreign key
    # on (partition_id, job_definition_id).
    validates :job_definition_id, presence: true

    scope :scoped_job, -> do
      where(arel_table[:job_id].eq(Ci::Processable.arel_table[:id]))
      .where(arel_table[:partition_id].eq(Ci::Processable.arel_table[:partition_id]))
    end

    # This scope is for use inside nested NOT EXISTS subqueries and adds the partition
    # equality predicate to the ON of the INNER JOIN. This is necessary to prevent the
    # planner from pulling the anti-join subquery up and flattening it with the outer
    # relation, which produces a very costly plan involving many seq scans.
    scope :joins_job_definition_scoped_by_job_partition, -> do
      instances = arel_table
      definitions = Ci::JobDefinition.arel_table
      outer_job = Ci::Processable.arel_table

      on_conditions =
        definitions[:id].eq(instances[:job_definition_id])
          .and(definitions[:partition_id].eq(instances[:partition_id]))
          .and(instances[:partition_id].eq(outer_job[:partition_id]))

      joins(instances.join(definitions).on(on_conditions).join_sources)
    end
  end
end
