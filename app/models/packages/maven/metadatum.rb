# frozen_string_literal: true
class Packages::Maven::Metadatum < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  belongs_to :package, class_name: 'Packages::Maven::Package'

  # TODO: Remove with the rollout of the FF maven_extract_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
  belongs_to :legacy_package, -> {
    where(package_type: :maven)
  }, class_name: 'Packages::Package', foreign_key: :package_id

  validates :package, presence: true, if: -> { maven_extract_package_model_enabled? }

  # TODO: Remove with the rollout of the FF maven_extract_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
  validates :legacy_package, presence: true, unless: -> { maven_extract_package_model_enabled? }

  validates :path,
    presence: true,
    format: { with: Gitlab::Regex.maven_path_regex }

  validates :app_group,
    presence: true,
    format: { with: Gitlab::Regex.maven_app_group_regex }

  validates :app_name,
    presence: true,
    format: { with: Gitlab::Regex.maven_app_name_regex }

  validate :maven_package_type, unless: -> { maven_extract_package_model_enabled? }

  scope :for_package_ids, ->(package_ids) { where(package_id: package_ids) }
  scope :with_path, ->(path) { where(path: path) }
  scope :order_created, -> { reorder('created_at ASC') }

  def self.pluck_app_name
    pluck(:app_name)
  end

  private

  def maven_package_type
    unless legacy_package&.maven?
      errors.add(:base, _('Package type must be Maven'))
    end
  end

  def maven_extract_package_model_enabled?
    Feature.enabled?(:maven_extract_package_model, Feature.current_request)
  end
  strong_memoize_attr :maven_extract_package_model_enabled?
end
