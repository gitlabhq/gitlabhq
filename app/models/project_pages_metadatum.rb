# frozen_string_literal: true

class ProjectPagesMetadatum < ApplicationRecord
  self.primary_key = :project_id

  belongs_to :project, inverse_of: :pages_metadatum

  scope :deployed, -> { where(deployed: true) }
end
