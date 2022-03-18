# frozen_string_literal: true

class ProjectPagesMetadatum < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include EachBatch
  include IgnorableColumns

  self.primary_key = :project_id

  ignore_columns :artifacts_archive_id, remove_with: '15.0', remove_after: '2022-04-22'

  belongs_to :project, inverse_of: :pages_metadatum
  belongs_to :pages_deployment

  scope :deployed, -> { where(deployed: true) }
  scope :only_on_legacy_storage, -> { deployed.where(pages_deployment: nil) }
  scope :with_project_route_and_deployment, -> { preload(:pages_deployment, project: [:namespace, :route]) }
end
