# frozen_string_literal: true

module Ci
  # The purpose of this class is to store immutable duplicate Processable related
  # data that can be disposed after all the pipelines that use it are archived.
  # Data that should be persisted forever, should be stored with Ci::Build model.
  class JobDefinition < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_job_definitions
    self.primary_key = :id

    query_constraints :id, :partition_id
    partitionable scope: ->(_) { Ci::Pipeline.current_partition_value }, partitioned: true

    belongs_to :project

    has_many :job_definition_instances, ->(definition) { in_partition(definition) },
      class_name: 'Ci::JobDefinitionInstance', partition_foreign_key: :partition_id,
      inverse_of: :job_definition

    has_many :jobs, ->(definition) { in_partition(definition) },
      through: :job_definition_instances,
      class_name: 'Ci::Processable', partition_foreign_key: :partition_id

    validates :project, presence: true

    # rubocop:disable Database/JsonbSizeLimit -- no updates
    validates :config, json_schema: { filename: 'ci_job_definitions_config' }
    # rubocop:enable Database/JsonbSizeLimit

    attribute :config, ::Gitlab::Database::Type::SymbolizedJsonb.new
  end
end
