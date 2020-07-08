# frozen_string_literal: true

module Packages
  module Composer
    class Metadatum < ApplicationRecord
      self.table_name = 'packages_composer_metadata'
      self.primary_key = :package_id

      belongs_to :package, -> { where(package_type: :composer) }, inverse_of: :composer_metadatum

      validates :package, :target_sha, :composer_json, presence: true
    end
  end
end
