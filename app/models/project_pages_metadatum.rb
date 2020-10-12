# frozen_string_literal: true

class ProjectPagesMetadatum < ApplicationRecord
  self.primary_key = :project_id

  belongs_to :project, inverse_of: :pages_metadatum
  belongs_to :artifacts_archive, class_name: 'Ci::JobArtifact'
  belongs_to :pages_deployment

  scope :deployed, -> { where(deployed: true) }
end
