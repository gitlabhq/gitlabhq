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

    validates :project, presence: true

    # rubocop:disable Database/JsonbSizeLimit -- no updates
    validates :config, json_schema: { filename: 'ci_job_definitions_config' }
    # rubocop:enable Database/JsonbSizeLimit

    attribute :config, ::Gitlab::Database::Type::SymbolizedJsonb.new
  end
end
