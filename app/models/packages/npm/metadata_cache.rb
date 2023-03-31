# frozen_string_literal: true

module Packages
  module Npm
    class MetadataCache < ApplicationRecord
      belongs_to :project, inverse_of: :npm_metadata_caches

      validates :file, :package_name, :project, :size, presence: true
      validates :package_name, uniqueness: { scope: :project_id }
      validates :package_name, format: { with: Gitlab::Regex.package_name_regex }
      validates :package_name, format: { with: Gitlab::Regex.npm_package_name_regex }
    end
  end
end
