# frozen_string_literal: true
class Packages::Tag < ApplicationRecord
  belongs_to :package, inverse_of: :tags

  validates :package, :name, presence: true

  FOR_PACKAGES_TAGS_LIMIT = 200
  NUGET_TAGS_SEPARATOR = ' ' # https://docs.microsoft.com/en-us/nuget/reference/nuspec#tags

  scope :preload_package, -> { preload(:package) }
  scope :with_name, -> (name) { where(name: name) }

  def self.for_packages(packages)
    where(package_id: packages.select(:id))
      .order(updated_at: :desc)
      .limit(FOR_PACKAGES_TAGS_LIMIT)
  end
end
