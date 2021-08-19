# frozen_string_literal: true

module Ci
  class BuildTraceMetadata < Ci::ApplicationRecord
    self.table_name = 'ci_build_trace_metadata'
    self.primary_key = :build_id

    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :trace_artifact, class_name: 'Ci::JobArtifact'

    validates :build, presence: true
  end
end
