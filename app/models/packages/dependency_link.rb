# frozen_string_literal: true
class Packages::DependencyLink < ApplicationRecord
  include EachBatch

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
  scope :for_packages, ->(packages) { where(package: packages) }
  scope :preload_dependency, -> { preload(:dependency) }
  scope :preload_nuget_metadatum, -> { preload(:nuget_metadatum) }
  scope :select_dependency_id, -> { select(:dependency_id) }

  def self.dependency_ids_grouped_by_type(packages)
    inner_query = where(package_id: packages)
                    .select('
                      package_id,
                      dependency_type,
                      ARRAY_AGG(dependency_id) as dependency_ids
                    ')
                    .group(:package_id, :dependency_type)

    cte = Gitlab::SQL::CTE.new(:dependency_links_cte, inner_query)
    cte_alias = cte.table.alias(table_name)

    with(cte.to_arel)
      .select('
        package_id,
        JSON_OBJECT_AGG(
          dependency_type,
          dependency_ids
      ) AS dependency_ids_by_type
      ')
      .from(cte_alias)
      .group(:package_id)
  end
end
