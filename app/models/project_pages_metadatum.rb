# frozen_string_literal: true

class ProjectPagesMetadatum < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include EachBatch

  self.primary_key = :project_id

  belongs_to :project, inverse_of: :pages_metadatum
  belongs_to :artifacts_archive, class_name: 'Ci::JobArtifact'
  belongs_to :pages_deployment

  scope :deployed, -> { where(deployed: true) }
  scope :only_on_legacy_storage, -> { deployed.where(pages_deployment: nil) }
  scope :with_project_route_and_deployment, -> { preload(:pages_deployment, project: [:namespace, :route]) }
end
