# frozen_string_literal: true
class Packages::Tag < ApplicationRecord
  belongs_to :package, inverse_of: :tags
  belongs_to :project

  validates :package, :name, presence: true

  before_save :ensure_project_id

  FOR_PACKAGES_TAGS_LIMIT = 200
  NUGET_TAGS_SEPARATOR = ' ' # https://docs.microsoft.com/en-us/nuget/reference/nuspec#tags

  scope :preload_package, -> { preload(:package) }
  scope :with_name, ->(name) { where(name: name) }

  def self.for_package_ids(package_ids)
    where(package_id: package_ids)
      .order(updated_at: :desc)
      .limit(FOR_PACKAGES_TAGS_LIMIT)
  end

  def ensure_project_id
    self.project_id ||= package.project_id
  end
end
