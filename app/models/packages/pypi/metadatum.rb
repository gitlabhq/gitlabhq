# frozen_string_literal: true

class Packages::Pypi::Metadatum < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  self.primary_key = :package_id

  MAX_REQUIRED_PYTHON_LENGTH = 255
  MAX_KEYWORDS_LENGTH = 1024
  MAX_METADATA_VERSION_LENGTH = 16
  MAX_AUTHOR_EMAIL_LENGTH = 2048
  MAX_SUMMARY_LENGTH = 255
  MAX_DESCRIPTION_LENGTH = 4000
  MAX_DESCRIPTION_CONTENT_TYPE_LENGTH = 128

  belongs_to :package, class_name: 'Packages::Pypi::Package', inverse_of: :pypi_metadatum

  # TODO: Remove with the rollout of the FF pypi_extract_pypi_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/480692
  belongs_to :legacy_package, -> {
    where(package_type: :pypi)
  }, inverse_of: :pypi_metadatum, class_name: 'Packages::Package', foreign_key: :package_id

  validates :package, presence: true, if: -> { pypi_extract_pypi_package_model_enabled? }

  # TODO: Remove with the rollout of the FF pypi_extract_pypi_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/480692
  validates :legacy_package, presence: true, unless: -> { pypi_extract_pypi_package_model_enabled? }

  with_options allow_nil: true do
    validates :keywords, length: { maximum: MAX_KEYWORDS_LENGTH }
    validates :metadata_version, length: { maximum: MAX_METADATA_VERSION_LENGTH }
    validates :author_email, length: { maximum: MAX_AUTHOR_EMAIL_LENGTH }
    validates :summary, length: { maximum: MAX_SUMMARY_LENGTH }
    validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH }
    validates :description_content_type, length: { maximum: MAX_DESCRIPTION_CONTENT_TYPE_LENGTH }
  end
  validates :required_python, length: { maximum: MAX_REQUIRED_PYTHON_LENGTH }, allow_nil: false

  validate :pypi_package_type, unless: -> { pypi_extract_pypi_package_model_enabled? }

  private

  def pypi_package_type
    unless legacy_package&.pypi?
      errors.add(:base, _('Package type must be PyPi'))
    end
  end

  def pypi_extract_pypi_package_model_enabled?
    Feature.enabled?(:pypi_extract_pypi_package_model, Feature.current_request)
  end
  strong_memoize_attr :pypi_extract_pypi_package_model_enabled?
end
