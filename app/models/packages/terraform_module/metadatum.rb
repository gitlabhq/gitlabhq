# frozen_string_literal: true

module Packages
  module TerraformModule
    class Metadatum < ApplicationRecord
      self.primary_key = :package_id

      MAX_FIELDS_SIZE = 10.megabytes

      belongs_to :package, -> { where(package_type: :terraform_module) }, inverse_of: :terraform_module_metadatum
      belongs_to :project

      validates :package, :project, :fields, presence: true
      validates :fields, json_schema: { filename: 'terraform_module_metadata' }
      validate :terraform_module_package_type
      validate :ensure_fields_size

      private

      def terraform_module_package_type
        return if package&.terraform_module?

        errors.add(:base, _('Package type must be Terraform Module'))
      end

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
