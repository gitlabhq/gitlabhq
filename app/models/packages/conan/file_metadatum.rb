# frozen_string_literal: true

class Packages::Conan::FileMetadatum < ApplicationRecord
  belongs_to :package_file, inverse_of: :conan_file_metadatum

  DEFAULT_PACKAGE_REVISION = '0'
  DEFAULT_RECIPE_REVISION = '0'

  validates :package_file, presence: true

  validates :recipe_revision,
    presence: true,
    format: { with: Gitlab::Regex.conan_revision_regex }

  validates :package_revision, absence: true, if: :recipe_file?
  validates :package_revision, format: { with: Gitlab::Regex.conan_revision_regex }, if: :package_file?

  validates :conan_package_reference, absence: true, if: :recipe_file?
  validates :conan_package_reference, format: { with: Gitlab::Regex.conan_package_reference_regex }, if: :package_file?
  validate :conan_package_type

  enum conan_file_type: { recipe_file: 1, package_file: 2 }

  RECIPE_FILES = ::Gitlab::Regex::Packages::CONAN_RECIPE_FILES
  PACKAGE_FILES = ::Gitlab::Regex::Packages::CONAN_PACKAGE_FILES
  PACKAGE_BINARY = 'conan_package.tgz'

  private

  def conan_package_type
    unless package_file&.package&.conan?
      errors.add(:base, _('Package type must be Conan'))
    end
  end
end
