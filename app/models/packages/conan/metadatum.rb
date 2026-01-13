# frozen_string_literal: true

class Packages::Conan::Metadatum < ApplicationRecord
  NONE_VALUE = '_'

  belongs_to :package, class_name: 'Packages::Conan::Package', inverse_of: :conan_metadatum

  validates :package, presence: true

  validates :package_username,
    :package_channel,
    presence: true,
    format: { with: Gitlab::Regex.conan_recipe_user_channel_regex }

  validate :ensure_username_with_channel

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

  def self.validate_username_and_channel(username, channel)
    return if channel == NONE_VALUE || username != NONE_VALUE

    yield if block_given?
  end

  private

  def ensure_username_with_channel
    self.class.validate_username_and_channel(package_username, package_channel) do
      errors.add(:package_username, _('must be specified when channel is provided'))
    end
  end
end
