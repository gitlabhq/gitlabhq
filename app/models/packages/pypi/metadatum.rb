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

  validates :package, presence: true

  with_options allow_nil: true do
    validates :keywords, length: { maximum: MAX_KEYWORDS_LENGTH }
    validates :metadata_version, length: { maximum: MAX_METADATA_VERSION_LENGTH }
    validates :author_email, length: { maximum: MAX_AUTHOR_EMAIL_LENGTH }
    validates :summary, length: { maximum: MAX_SUMMARY_LENGTH }
    validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH }
    validates :description_content_type, length: { maximum: MAX_DESCRIPTION_CONTENT_TYPE_LENGTH }
  end
  validates :required_python, length: { maximum: MAX_REQUIRED_PYTHON_LENGTH }, allow_nil: false
end
