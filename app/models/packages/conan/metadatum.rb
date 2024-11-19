# frozen_string_literal: true

class Packages::Conan::Metadatum < ApplicationRecord
  NONE_VALUE = '_'

  belongs_to :package, class_name: 'Packages::Conan::Package', inverse_of: :conan_metadatum

  validates :package, presence: true

  validates :package_username,
    :package_channel,
    presence: true,
    format: { with: Gitlab::Regex.conan_recipe_user_channel_regex }

  validate :username_channel_none_values

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
    return if (username != NONE_VALUE && channel != NONE_VALUE) ||
      (username == NONE_VALUE && channel == NONE_VALUE)

    none_field = username == NONE_VALUE ? :username : :channel

    yield(none_field)
  end

  private

  def username_channel_none_values
    self.class.validate_username_and_channel(package_username, package_channel) do |none_field|
      errors.add(:"package_#{none_field}", _("can't be solely blank"))
    end
  end
end
