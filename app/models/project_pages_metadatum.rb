# frozen_string_literal: true

class ProjectPagesMetadatum < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include EachBatch

  ignore_column :pages_deployment_id, remove_with: '17.11', remove_after: '2025-03-21'
  ignore_column :deployed, remove_with: '17.11', remove_after: '2025-03-21'

  self.primary_key = :project_id

  belongs_to :project, inverse_of: :pages_metadatum
  belongs_to :pages_deployment
end
