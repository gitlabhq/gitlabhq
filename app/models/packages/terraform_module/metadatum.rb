# frozen_string_literal: true

module Packages
  module TerraformModule
    class Metadatum < ApplicationRecord
      include Gitlab::Utils::StrongMemoize
      include SemanticVersionable

      self.primary_key = :package_id

      MAX_FIELDS_SIZE = 10.megabytes

      belongs_to :package, class_name: 'Packages::TerraformModule::Package', inverse_of: :terraform_module_metadatum
      belongs_to :project

      attribute :fields, default: -> { {} }

      ignore_column :semver_patch_convert_to_bigint, remove_with: '18.1', remove_after: '2025-05-20'

      validates :package, :project, presence: true
      validates :fields, json_schema: { filename: 'terraform_module_metadata', detail_errors: true },
        if: -> { fields.present? }
      validate :ensure_fields_size

      private

      def ensure_fields_size
        return if fields.to_s.size <= MAX_FIELDS_SIZE

        errors.add(
          :fields,
          :too_large,
          message: format(_('metadata is too large (maximum is %{max_size} characters)'), max_size: MAX_FIELDS_SIZE)
        )
      end
    end
  end
end
