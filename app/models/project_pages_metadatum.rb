# frozen_string_literal: true

class ProjectPagesMetadatum < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include EachBatch
  include IgnorableColumns

  self.primary_key = :project_id

  belongs_to :project, inverse_of: :pages_metadatum
  belongs_to :pages_deployment
end
