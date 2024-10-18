# frozen_string_literal: true

module Packages
  module TerraformModule
    class Metadatum < ApplicationRecord
      include Gitlab::Utils::StrongMemoize

      self.primary_key = :package_id

      MAX_FIELDS_SIZE = 10.megabytes

      belongs_to :package, class_name: 'Packages::TerraformModule::Package', inverse_of: :terraform_module_metadatum

      # TODO: Remove with the rollout of the FF terraform_extract_terraform_package_model
      # https://gitlab.com/gitlab-org/gitlab/-/issues/480692
      belongs_to :legacy_package, -> {
        where(package_type: :terraform_module)
      }, inverse_of: :terraform_module_metadatum, class_name: 'Packages::Package', foreign_key: :package_id

      belongs_to :project

      validates :package, presence: true, if: -> { terraform_extract_terraform_package_model_enabled? }

      # TODO: Remove with the rollout of the FF terraform_extract_terraform_package_model
      # https://gitlab.com/gitlab-org/gitlab/-/issues/480692
      validates :legacy_package, presence: true, unless: -> { terraform_extract_terraform_package_model_enabled? }

      validates :project, :fields, presence: true
      validates :fields, json_schema: { filename: 'terraform_module_metadata', detail_errors: true }
      validate :terraform_module_package_type, unless: -> { terraform_extract_terraform_package_model_enabled? }
      validate :ensure_fields_size

      private

      def terraform_module_package_type
        return if legacy_package&.terraform_module?

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

      def terraform_extract_terraform_package_model_enabled?
        Feature.enabled?(:terraform_extract_terraform_package_model, Feature.current_request)
      end
      strong_memoize_attr :terraform_extract_terraform_package_model_enabled?
    end
  end
end
