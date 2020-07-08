# frozen_string_literal: true
class Packages::DependencyLink < ApplicationRecord
  belongs_to :package, inverse_of: :dependency_links
  belongs_to :dependency, inverse_of: :dependency_links, class_name: 'Packages::Dependency'
  has_one :nuget_metadatum, inverse_of: :dependency_link, class_name: 'Packages::Nuget::DependencyLinkMetadatum'

  validates :package, :dependency, presence: true

  validates :dependency_type,
    uniqueness: { scope: %i[package_id dependency_id] }

  enum dependency_type: { dependencies: 1, devDependencies: 2, bundleDependencies: 3, peerDependencies: 4 }

  scope :with_dependency_type, ->(dependency_type) { where(dependency_type: dependency_type) }
  scope :includes_dependency, -> { includes(:dependency) }
  scope :for_package, ->(package) { where(package_id: package.id) }
  scope :preload_dependency, -> { preload(:dependency) }
  scope :preload_nuget_metadatum, -> { preload(:nuget_metadatum) }
end
