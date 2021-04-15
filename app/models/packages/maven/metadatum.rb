# frozen_string_literal: true
class Packages::Maven::Metadatum < ApplicationRecord
  belongs_to :package, -> { where(package_type: :maven) }

  validates :package, presence: true

  validates :path,
    presence: true,
    format: { with: Gitlab::Regex.maven_path_regex }

  validates :app_group,
    presence: true,
    format: { with: Gitlab::Regex.maven_app_group_regex }

  validates :app_name,
    presence: true,
    format: { with: Gitlab::Regex.maven_app_name_regex }

  validate :maven_package_type

  scope :for_package_ids, -> (package_ids) { where(package_id: package_ids) }
  scope :with_path, ->(path) { where(path: path) }
  scope :order_created, -> { reorder('created_at ASC') }

  def self.pluck_app_name
    pluck(:app_name)
  end

  private

  def maven_package_type
    unless package&.maven?
      errors.add(:base, _('Package type must be Maven'))
    end
  end
end
