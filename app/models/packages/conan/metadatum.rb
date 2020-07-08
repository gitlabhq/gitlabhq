# frozen_string_literal: true

class Packages::Conan::Metadatum < ApplicationRecord
  belongs_to :package, -> { where(package_type: :conan) }, inverse_of: :conan_metadatum

  validates :package, presence: true

  validates :package_username,
    presence: true,
    format: { with: Gitlab::Regex.conan_recipe_component_regex }

  validates :package_channel,
    presence: true,
    format: { with: Gitlab::Regex.conan_recipe_component_regex }

  validate :conan_package_type

  def recipe
    "#{package.name}/#{package.version}@#{package_username}/#{package_channel}"
  end

  def recipe_path
    recipe.tr('@', '/')
  end

  def self.package_username_from(full_path:)
    full_path.tr('/', '+')
  end

  def self.full_path_from(package_username:)
    package_username.tr('+', '/')
  end

  private

  def conan_package_type
    unless package&.conan?
      errors.add(:base, _('Package type must be Conan'))
    end
  end
end
