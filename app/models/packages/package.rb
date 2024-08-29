# frozen_string_literal: true
class Packages::Package < ApplicationRecord
  include EachBatch
  include Sortable
  include Gitlab::SQL::Pattern
  include UsageStatistics
  include Gitlab::Utils::StrongMemoize
  include Packages::Installable
  include Packages::Downloadable
  include EnumInheritance

  DISPLAYABLE_STATUSES = [:default, :error].freeze
  INSTALLABLE_STATUSES = [:default, :hidden].freeze
  STATUS_MESSAGE_MAX_LENGTH = 255

  enum package_type: {
    maven: 1,
    npm: 2,
    conan: 3,
    nuget: 4,
    pypi: 5,
    composer: 6,
    generic: 7,
    golang: 8,
    debian: 9,
    rubygems: 10,
    helm: 11,
    terraform_module: 12,
    rpm: 13,
    ml_model: 14
  }

  enum status: { default: 0, hidden: 1, processing: 2, error: 3, pending_destruction: 4 }

  belongs_to :project
  belongs_to :creator, class_name: 'User'

  # TODO: Remove with the rollout of the FF generic_extract_generic_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/479933
  after_create_commit :publish_creation_event, if: -> { generic? && Feature.disabled?(:generic_extract_generic_package_model, Feature.current_request) }

  # package_files must be destroyed by ruby code in order to properly remove carrierwave uploads and update project statistics
  has_many :package_files, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  # TODO: put the installable default scope on the :package_files association once the dependent: :destroy is removed
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/349191
  has_many :installable_package_files, -> { installable }, class_name: 'Packages::PackageFile', inverse_of: :package
  has_many :installable_nuget_package_files, -> { installable.with_nuget_format }, class_name: 'Packages::PackageFile', inverse_of: :package
  has_many :dependency_links, inverse_of: :package, class_name: 'Packages::DependencyLink'
  has_many :tags, inverse_of: :package, class_name: 'Packages::Tag'
  has_one :pypi_metadatum, inverse_of: :package, class_name: 'Packages::Pypi::Metadatum'
  has_one :maven_metadatum, inverse_of: :package, class_name: 'Packages::Maven::Metadatum'
  has_one :nuget_metadatum, inverse_of: :package, class_name: 'Packages::Nuget::Metadatum'
  has_many :nuget_symbols, inverse_of: :package, class_name: 'Packages::Nuget::Symbol'
  has_one :npm_metadatum, inverse_of: :package, class_name: 'Packages::Npm::Metadatum'
  has_one :terraform_module_metadatum, inverse_of: :package, class_name: 'Packages::TerraformModule::Metadatum'
  has_many :build_infos, inverse_of: :package
  has_many :pipelines, through: :build_infos, disable_joins: true
  has_many :matching_package_protection_rules, ->(package) { where(package_type: package.package_type).for_package_name(package.name) }, through: :project, source: :package_protection_rules

  accepts_nested_attributes_for :maven_metadatum

  validates :project, presence: true
  validates :name, presence: true

  validates :name, format: { with: Gitlab::Regex.package_name_regex }, unless: -> { conan? || generic? || debian? }

  validates :name,
    uniqueness: {
      scope: %i[project_id version package_type],
      conditions: -> { not_pending_destruction }
    },
    unless: -> { pending_destruction? || conan? }

  validate :npm_package_already_taken, if: :npm?

  # TODO: Remove with the rollout of the FF generic_extract_generic_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/479933
  validates :name, format: { with: Gitlab::Regex.generic_package_name_regex }, if: :generic?

  validates :name, format: { with: Gitlab::Regex.npm_package_name_regex, message: Gitlab::Regex.npm_package_name_regex_message }, if: :npm?
  validates :name, format: { with: Gitlab::Regex.nuget_package_name_regex }, if: :nuget?
  validates :name, format: { with: Gitlab::Regex.terraform_module_package_name_regex }, if: :terraform_module?
  validates :version, format: { with: Gitlab::Regex.nuget_version_regex }, if: :nuget?
  validates :version, format: { with: Gitlab::Regex.maven_version_regex }, if: -> { version? && maven? }
  validates :version, format: { with: Gitlab::Regex.pypi_version_regex }, if: :pypi?
  validates :version, format: { with: Gitlab::Regex.semver_regex, message: Gitlab::Regex.semver_regex_message },
    if: -> { npm? || terraform_module? }

  # TODO: Remove with the rollout of the FF generic_extract_generic_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/479933
  validates :version,
    presence: true,
    format: { with: Gitlab::Regex.generic_package_version_regex },
    if: :generic?

  scope :for_projects, ->(project_ids) { where(project_id: project_ids) }
  scope :with_name, ->(name) { where(name: name) }
  scope :with_name_like, ->(name) { where(arel_table[:name].matches(name)) }

  scope :with_normalized_pypi_name, ->(name) do
    where(
      "LOWER(regexp_replace(name, ?, '-', 'g')) = ?",
      Gitlab::Regex::Packages::PYPI_NORMALIZED_NAME_REGEX_STRING,
      name.downcase
    )
  end

  scope :with_case_insensitive_version, ->(version) do
    where('LOWER(version) = ?', version.downcase)
  end

  scope :with_case_insensitive_name, ->(name) do
    where(arel_table[:name].lower.eq(name.downcase))
  end

  scope :with_nuget_version_or_normalized_version, ->(version, with_normalized: true) do
    relation = with_case_insensitive_version(version)

    return relation unless with_normalized

    relation
      .left_joins(:nuget_metadatum)
      .or(
        merge(Packages::Nuget::Metadatum.normalized_version_in(version))
      )
  end

  scope :search_by_name, ->(query) { fuzzy_search(query, [:name], use_minimum_char_limit: false) }
  scope :with_version, ->(version) { where(version: version) }
  scope :without_version_like, ->(version) { where.not(arel_table[:version].matches(version)) }
  scope :with_package_type, ->(package_type) { where(package_type: package_type) }
  scope :without_package_type, ->(package_type) { where.not(package_type: package_type) }
  scope :displayable, -> { with_status(DISPLAYABLE_STATUSES) }
  scope :including_project_route, -> { includes(project: :route) }
  scope :including_project_namespace_route, -> { includes(project: { namespace: :route }) }
  scope :including_tags, -> { includes(:tags) }
  scope :including_dependency_links, -> { includes(dependency_links: :dependency) }
  scope :including_dependency_links_with_nuget_metadatum, -> { includes(dependency_links: [:dependency, :nuget_metadatum]) }

  scope :preload_npm_metadatum, -> { preload(:npm_metadatum) }
  scope :preload_nuget_metadatum, -> { preload(:nuget_metadatum) }
  scope :preload_pypi_metadatum, -> { preload(:pypi_metadatum) }

  scope :with_npm_scope, ->(scope) do
    npm.where("position('/' in packages_packages.name) > 0 AND split_part(packages_packages.name, '/', 1) = :package_scope", package_scope: "@#{sanitize_sql_like(scope)}")
  end

  scope :without_nuget_temporary_name, -> { where.not(name: Packages::Nuget::TEMPORARY_PACKAGE_NAME) }

  scope :has_version, -> { where.not(version: nil) }
  scope :preload_files, -> { preload(:installable_package_files) }
  scope :preload_nuget_files, -> { preload(:installable_nuget_package_files) }
  scope :preload_pipelines, -> { preload(pipelines: :user) }
  scope :preload_tags, -> { preload(:tags) }
  scope :limit_recent, ->(limit) { order_created_desc.limit(limit) }
  scope :select_distinct_name, -> { select(:name).distinct }

  # Sorting
  scope :order_created, -> { reorder(created_at: :asc) }
  scope :order_created_desc, -> { reorder(created_at: :desc) }
  scope :order_name, -> { reorder(name: :asc) }
  scope :order_name_desc, -> { reorder(name: :desc) }
  scope :order_version, -> { reorder(version: :asc) }
  scope :order_version_desc, -> { reorder(version: :desc) }
  scope :order_type, -> { reorder(package_type: :asc) }
  scope :order_type_desc, -> { reorder(package_type: :desc) }
  scope :order_project_name, -> { joins(:project).reorder('projects.name ASC') }
  scope :order_project_name_desc, -> { joins(:project).reorder('projects.name DESC') }
  scope :order_by_package_file, -> { joins(:package_files).order('packages_package_files.created_at ASC') }

  scope :order_project_path, -> do
    build_keyset_order_on_joined_column(
      scope: joins(:project),
      attribute_name: 'project_path',
      column: Project.arel_table[:path],
      direction: :asc,
      nullable: :nulls_last
    )
  end

  scope :order_project_path_desc, -> do
    build_keyset_order_on_joined_column(
      scope: joins(:project),
      attribute_name: 'project_path',
      column: Project.arel_table[:path],
      direction: :desc,
      nullable: :nulls_first
    )
  end

  def self.inheritance_column = 'package_type'

  def self.inheritance_column_to_class_map
    hash = {
      ml_model: 'Packages::MlModel::Package',
      golang: 'Packages::Go::Package',
      rubygems: 'Packages::Rubygems::Package',
      conan: 'Packages::Conan::Package',
      rpm: 'Packages::Rpm::Package',
      debian: 'Packages::Debian::Package',
      composer: 'Packages::Composer::Package',
      helm: 'Packages::Helm::Package'
    }

    if Feature.enabled?(:generic_extract_generic_package_model, Feature.current_request)
      hash[:generic] = 'Packages::Generic::Package'
    end

    hash
  end

  def self.only_maven_packages_with_path(path, use_cte: false)
    if use_cte
      # This is an optimization fence which assumes that looking up the Metadatum record by path (globally)
      # and then filter down the packages (by project or by group and subgroups) will be cheaper than
      # looking up all packages within a project or group and filter them by path.

      inner_query = Packages::Maven::Metadatum.where(path: path).select(:id, :package_id)
      cte = Gitlab::SQL::CTE.new(:maven_metadata_by_path, inner_query)
      with(cte.to_arel)
        .joins('INNER JOIN maven_metadata_by_path ON maven_metadata_by_path.package_id=packages_packages.id')
    else
      joins(:maven_metadatum).where(packages_maven_metadata: { path: path })
    end
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

  def self.installable_statuses
    INSTALLABLE_STATUSES
  end

  def versions
    project.packages
           .preload_pipelines
           .including_tags
           .displayable
           .with_name(name)
           .where.not(version: version)
           .with_package_type(package_type)
           .order(:version)
  end

  # Technical debt: to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/281937
  def last_build_info
    build_infos.last
  end
  strong_memoize_attr :last_build_info

  # Technical debt: to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/281937
  def pipeline
    last_build_info&.pipeline
  end

  def tag_names
    tags.pluck(:name)
  end

  def infrastructure_package?
    terraform_module?
  end

  def package_settings
    project.namespace.package_settings
  end
  strong_memoize_attr :package_settings

  def sync_maven_metadata(user)
    return unless maven? && version? && user

    ::Packages::Maven::Metadata::SyncWorker.perform_async(user.id, project_id, name)
  end

  def sync_npm_metadata_cache
    return unless npm?

    ::Packages::Npm::CreateMetadataCacheWorker.perform_async(project_id, name)
  end

  def create_build_infos!(build)
    return unless build&.pipeline

    # TODO: use an upsert call when https://gitlab.com/gitlab-org/gitlab/-/issues/339093 is implemented
    build_infos.find_or_create_by!(pipeline: build.pipeline)
  end

  def mark_package_files_for_destruction
    return unless pending_destruction?

    ::Packages::MarkPackageFilesForDestructionWorker.perform_async(id)
  end

  # As defined in PEP 503 https://peps.python.org/pep-0503/#normalized-names
  def normalized_pypi_name
    return name unless pypi?

    name.gsub(/#{Gitlab::Regex::Packages::PYPI_NORMALIZED_NAME_REGEX_STRING}/o, '-').downcase
  end

  def normalized_nuget_version
    return unless nuget?

    nuget_metadatum&.normalized_version
  end

  def publish_creation_event
    ::Gitlab::EventStore.publish(
      ::Packages::PackageCreatedEvent.new(data: {
        project_id: project_id,
        id: id,
        name: name,
        version: version,
        package_type: package_type
      })
    )
  end

  private

  def npm_package_already_taken
    return unless project
    return unless follows_npm_naming_convention?

    if project.package_already_taken?(name, version, package_type: :npm)
      errors.add(:base, _('Package already exists'))
    end
  end

  # https://docs.gitlab.com/ee/user/packages/npm_registry/#package-naming-convention
  def follows_npm_naming_convention?
    return false unless project&.root_namespace&.path

    project.root_namespace.path == ::Packages::Npm.scope_of(name)
  end
end
