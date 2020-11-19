# frozen_string_literal: true
class Packages::Package < ApplicationRecord
  include Sortable
  include Gitlab::SQL::Pattern
  include UsageStatistics
  include Gitlab::Utils::StrongMemoize

  belongs_to :project
  belongs_to :creator, class_name: 'User'

  # package_files must be destroyed by ruby code in order to properly remove carrierwave uploads and update project statistics
  has_many :package_files, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :dependency_links, inverse_of: :package, class_name: 'Packages::DependencyLink'
  has_many :tags, inverse_of: :package, class_name: 'Packages::Tag'
  has_one :conan_metadatum, inverse_of: :package, class_name: 'Packages::Conan::Metadatum'
  has_one :pypi_metadatum, inverse_of: :package, class_name: 'Packages::Pypi::Metadatum'
  has_one :maven_metadatum, inverse_of: :package, class_name: 'Packages::Maven::Metadatum'
  has_one :nuget_metadatum, inverse_of: :package, class_name: 'Packages::Nuget::Metadatum'
  has_one :composer_metadatum, inverse_of: :package, class_name: 'Packages::Composer::Metadatum'
  has_many :build_infos, inverse_of: :package
  has_many :pipelines, through: :build_infos

  accepts_nested_attributes_for :conan_metadatum
  accepts_nested_attributes_for :maven_metadatum

  delegate :recipe, :recipe_path, to: :conan_metadatum, prefix: :conan

  validates :project, presence: true
  validates :name, presence: true

  validates :name, format: { with: Gitlab::Regex.package_name_regex }, unless: -> { conan? || generic? }

  validates :name,
    uniqueness: { scope: %i[project_id version package_type] }, unless: :conan?

  validate :valid_conan_package_recipe, if: :conan?
  validate :valid_npm_package_name, if: :npm?
  validate :valid_composer_global_name, if: :composer?
  validate :package_already_taken, if: :npm?
  validates :name, format: { with: Gitlab::Regex.conan_recipe_component_regex }, if: :conan?
  validates :name, format: { with: Gitlab::Regex.generic_package_name_regex }, if: :generic?
  validates :name, format: { with: Gitlab::Regex.nuget_package_name_regex }, if: :nuget?
  validates :version, format: { with: Gitlab::Regex.nuget_version_regex }, if: :nuget?
  validates :version, format: { with: Gitlab::Regex.conan_recipe_component_regex }, if: :conan?
  validates :version, format: { with: Gitlab::Regex.maven_version_regex }, if: -> { version? && maven? }
  validates :version, format: { with: Gitlab::Regex.pypi_version_regex }, if: :pypi?
  validates :version, format: { with: Gitlab::Regex.prefixed_semver_regex }, if: :golang?
  validates :version, format: { with: Gitlab::Regex.semver_regex }, if: -> { composer_tag_version? || npm? }

  validates :version,
    presence: true,
    format: { with: Gitlab::Regex.generic_package_version_regex },
    if: :generic?

  enum package_type: { maven: 1, npm: 2, conan: 3, nuget: 4, pypi: 5, composer: 6, generic: 7, golang: 8, debian: 9 }

  scope :with_name, ->(name) { where(name: name) }
  scope :with_name_like, ->(name) { where(arel_table[:name].matches(name)) }
  scope :with_normalized_pypi_name, ->(name) { where("LOWER(regexp_replace(name, '[-_.]+', '-', 'g')) = ?", name.downcase) }
  scope :search_by_name, ->(query) { fuzzy_search(query, [:name], use_minimum_char_limit: false) }
  scope :with_version, ->(version) { where(version: version) }
  scope :without_version_like, -> (version) { where.not(arel_table[:version].matches(version)) }
  scope :with_package_type, ->(package_type) { where(package_type: package_type) }
  scope :including_build_info, -> { includes(pipelines: :user) }
  scope :including_project_route, -> { includes(project: { namespace: :route }) }
  scope :including_tags, -> { includes(:tags) }

  scope :with_conan_channel, ->(package_channel) do
    joins(:conan_metadatum).where(packages_conan_metadata: { package_channel: package_channel })
  end
  scope :with_conan_username, ->(package_username) do
    joins(:conan_metadatum).where(packages_conan_metadata: { package_username: package_username })
  end

  scope :with_composer_target, -> (target) do
    includes(:composer_metadatum)
      .joins(:composer_metadatum)
      .where(Packages::Composer::Metadatum.table_name => { target_sha: target })
  end
  scope :preload_composer, -> { preload(:composer_metadatum) }

  scope :without_nuget_temporary_name, -> { where.not(name: Packages::Nuget::CreatePackageService::TEMPORARY_PACKAGE_NAME) }

  scope :has_version, -> { where.not(version: nil) }
  scope :processed, -> do
    where.not(package_type: :nuget).or(
      where.not(name: Packages::Nuget::CreatePackageService::TEMPORARY_PACKAGE_NAME)
    )
  end
  scope :preload_files, -> { preload(:package_files) }
  scope :last_of_each_version, -> { where(id: all.select('MAX(id) AS id').group(:version)) }
  scope :limit_recent, ->(limit) { order_created_desc.limit(limit) }
  scope :select_distinct_name, -> { select(:name).distinct }

  # Sorting
  scope :order_created, -> { reorder('created_at ASC') }
  scope :order_created_desc, -> { reorder('created_at DESC') }
  scope :order_name, -> { reorder('name ASC') }
  scope :order_name_desc, -> { reorder('name DESC') }
  scope :order_version, -> { reorder('version ASC') }
  scope :order_version_desc, -> { reorder('version DESC') }
  scope :order_type, -> { reorder('package_type ASC') }
  scope :order_type_desc, -> { reorder('package_type DESC') }
  scope :order_project_name, -> { joins(:project).reorder('projects.name ASC') }
  scope :order_project_name_desc, -> { joins(:project).reorder('projects.name DESC') }
  scope :order_project_path, -> { joins(:project).reorder('projects.path ASC, id ASC') }
  scope :order_project_path_desc, -> { joins(:project).reorder('projects.path DESC, id DESC') }

  def self.for_projects(projects)
    return none unless projects.any?

    where(project_id: projects)
  end

  def self.only_maven_packages_with_path(path)
    joins(:maven_metadatum).where(packages_maven_metadata: { path: path })
  end

  def self.by_name_and_file_name(name, file_name)
    with_name(name)
      .joins(:package_files)
      .where(packages_package_files: { file_name: file_name }).last!
  end

  def self.by_file_name_and_sha256(file_name, sha256)
    joins(:package_files)
      .where(packages_package_files: { file_name: file_name, file_sha256: sha256 }).last!
  end

  def self.by_name_and_version!(name, version)
    find_by!(name: name, version: version)
  end

  def self.pluck_names
    pluck(:name)
  end

  def self.pluck_versions
    pluck(:version)
  end

  def self.sort_by_attribute(method)
    case method.to_s
    when 'created_asc' then order_created
    when 'created_at_asc' then order_created
    when 'name_asc' then order_name
    when 'name_desc' then order_name_desc
    when 'version_asc' then order_version
    when 'version_desc' then order_version_desc
    when 'type_asc' then order_type
    when 'type_desc' then order_type_desc
    when 'project_name_asc' then order_project_name
    when 'project_name_desc' then order_project_name_desc
    when 'project_path_asc' then order_project_path
    when 'project_path_desc' then order_project_path_desc
    else
      order_created_desc
    end
  end

  def versions
    project.packages
           .including_build_info
           .including_tags
           .with_name(name)
           .where.not(version: version)
           .with_package_type(package_type)
           .order(:version)
  end

  # Technical debt: to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/281937
  def original_build_info
    strong_memoize(:original_build_info) do
      build_infos.first
    end
  end

  # Technical debt: to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/281937
  def pipeline
    original_build_info&.pipeline
  end

  def tag_names
    tags.pluck(:name)
  end

  private

  def composer_tag_version?
    composer? && !Gitlab::Regex.composer_dev_version_regex.match(version.to_s)
  end

  def valid_conan_package_recipe
    recipe_exists = project.packages
                           .conan
                           .includes(:conan_metadatum)
                           .with_name(name)
                           .with_version(version)
                           .with_conan_channel(conan_metadatum.package_channel)
                           .with_conan_username(conan_metadatum.package_username)
                           .id_not_in(id)
                           .exists?

    errors.add(:base, _('Package recipe already exists')) if recipe_exists
  end

  def valid_composer_global_name
    # .default_scoped is required here due to a bug in rails that leaks
    # the scope and adds `self` to the query incorrectly
    # See https://github.com/rails/rails/pull/35186
    if Packages::Package.default_scoped.composer.with_name(name).where.not(project_id: project_id).exists?
      errors.add(:name, 'is already taken by another project')
    end
  end

  def valid_npm_package_name
    return unless project&.root_namespace

    unless name =~ %r{\A@#{project.root_namespace.path}/[^/]+\z}
      errors.add(:name, 'is not valid')
    end
  end

  def package_already_taken
    return unless project

    if project.package_already_taken?(name)
      errors.add(:base, _('Package already exists'))
    end
  end
end
