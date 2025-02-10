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

  DISPLAYABLE_STATUSES = [:default, :error, :deprecated].freeze
  INSTALLABLE_STATUSES = [:default, :hidden, :deprecated].freeze
  DETAILED_INFO_STATUSES = [:default, :deprecated].freeze
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

  enum status: { default: 0, hidden: 1, processing: 2, error: 3, pending_destruction: 4, deprecated: 5 }

  belongs_to :project
  belongs_to :creator, class_name: 'User'

  # package_files must be destroyed by ruby code in order to properly remove carrierwave uploads and update project statistics
  has_many :package_files, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  # TODO: put the installable default scope on the :package_files association once the dependent: :destroy is removed
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/349191
  has_many :installable_package_files, -> { installable }, class_name: 'Packages::PackageFile', inverse_of: :package
  has_many :dependency_links, inverse_of: :package, class_name: 'Packages::DependencyLink'
  has_many :tags, inverse_of: :package, class_name: 'Packages::Tag'

  # TODO: Remove with the rollout of the FF maven_extract_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
  has_one :maven_metadatum, inverse_of: :legacy_package, class_name: 'Packages::Maven::Metadatum'

  has_many :build_infos, inverse_of: :package
  has_many :pipelines, through: :build_infos, disable_joins: true

  # TODO: Remove with the rollout of the FF maven_extract_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
  accepts_nested_attributes_for :maven_metadatum

  # TODO: Remove with the rollout of the FF maven_extract_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
  before_validation :prevent_concurrent_inserts, on: :create, if: :maven?

  validates :project, presence: true
  validates :name, presence: true

  validates :name, format: { with: Gitlab::Regex.package_name_regex }, unless: -> { conan? || generic? || debian? }

  validates :name,
    uniqueness: {
      scope: %i[project_id version package_type],
      conditions: -> { not_pending_destruction }
    },
    unless: -> { pending_destruction? || conan? }

  validates :version, format: { with: Gitlab::Regex.maven_version_regex }, if: -> { version? && maven? }

  scope :for_projects, ->(project_ids) { where(project_id: project_ids) }
  scope :with_name, ->(name) { where(name: name) }
  scope :with_name_like, ->(name) { where(arel_table[:name].matches(name)) }

  scope :with_case_insensitive_version, ->(version) do
    where('LOWER(version) = ?', version.downcase)
  end

  scope :with_case_insensitive_name, ->(name) do
    where(arel_table[:name].lower.eq(name.downcase))
  end

  scope :search_by_name, ->(query) { fuzzy_search(query, [:name], use_minimum_char_limit: false) }
  scope :with_version, ->(version) { where(version: version) }
  scope :with_version_like, ->(version) { where(arel_table[:version].matches(version)) }
  scope :without_version_like, ->(version) { where.not(arel_table[:version].matches(version)) }
  scope :with_package_type, ->(package_type) { where(package_type: package_type) }
  scope :without_package_type, ->(package_type) { where.not(package_type: package_type) }
  scope :displayable, -> { with_status(DISPLAYABLE_STATUSES) }
  scope :including_project_route, -> { includes(project: :route) }
  scope :including_project_namespace_route, -> { includes(project: { namespace: :route }) }
  scope :including_tags, -> { includes(:tags) }
  scope :including_dependency_links, -> { includes(dependency_links: :dependency) }
  scope :has_version, -> { where.not(version: nil) }
  scope :preload_files, -> { preload(:installable_package_files) }
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
      helm: 'Packages::Helm::Package',
      generic: 'Packages::Generic::Package',
      pypi: 'Packages::Pypi::Package',
      terraform_module: 'Packages::TerraformModule::Package',
      nuget: 'Packages::Nuget::Package',
      npm: 'Packages::Npm::Package'
    }

    hash[:maven] = 'Packages::Maven::Package' if Feature.enabled?(:maven_extract_package_model, Feature.current_request)

    hash.freeze
  end

  # TODO: Remove with the rollout of the FF maven_extract_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
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

  def package_settings
    project.namespace.package_settings
  end
  strong_memoize_attr :package_settings

  # TODO: Remove with the rollout of the FF maven_extract_package_model
  # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
  def sync_maven_metadata(user)
    return unless maven? && version? && user

    ::Packages::Maven::Metadata::SyncWorker.perform_async(user.id, project_id, name)
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

  def detailed_info?
    DETAILED_INFO_STATUSES.include?(status.to_sym)
  end

  private

  # This method will block while another database transaction attempts to insert the same data.
  # After the lock is released by the other transaction, the uniqueness validation may fail
  # with record not unique validation error.

  # Without this block the uniqueness validation wouldn't be able to detect duplicated
  # records as transactions can't see each other's changes.

  # This is a temp advisory lock to prevent race conditions. We will switch to use database `upsert`
  # once we have a database unique index: https://gitlab.com/gitlab-org/gitlab/-/issues/424238#note_2187274213
  def prevent_concurrent_inserts
    lock_key = [self.class.table_name, project_id, name, version].join('-')
    lock_expression = "hashtext(#{connection.quote(lock_key)})"

    connection.execute("SELECT pg_advisory_xact_lock(#{lock_expression})")
  end
end
