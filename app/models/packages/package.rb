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

  after_create_commit :publish_creation_event, if: :generic?

  # package_files must be destroyed by ruby code in order to properly remove carrierwave uploads and update project statistics
  has_many :package_files, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  # TODO: put the installable default scope on the :package_files association once the dependent: :destroy is removed
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/349191
  has_many :installable_package_files, -> { installable }, class_name: 'Packages::PackageFile', inverse_of: :package
  has_many :installable_nuget_package_files, -> { installable.with_nuget_format }, class_name: 'Packages::PackageFile', inverse_of: :package
  has_many :dependency_links, inverse_of: :package, class_name: 'Packages::DependencyLink'
  has_many :tags, inverse_of: :package, class_name: 'Packages::Tag'
  has_one :conan_metadatum, inverse_of: :package, class_name: 'Packages::Conan::Metadatum'
  has_one :pypi_metadatum, inverse_of: :package, class_name: 'Packages::Pypi::Metadatum'
  has_one :maven_metadatum, inverse_of: :package, class_name: 'Packages::Maven::Metadatum'
  has_one :nuget_metadatum, inverse_of: :package, class_name: 'Packages::Nuget::Metadatum'
  has_many :nuget_symbols, inverse_of: :package, class_name: 'Packages::Nuget::Symbol'
  has_one :composer_metadatum, inverse_of: :package, class_name: 'Packages::Composer::Metadatum'
  has_one :rpm_metadatum, inverse_of: :package, class_name: 'Packages::Rpm::Metadatum'
  has_one :npm_metadatum, inverse_of: :package, class_name: 'Packages::Npm::Metadatum'
  has_one :terraform_module_metadatum, inverse_of: :package, class_name: 'Packages::TerraformModule::Metadatum'
  has_many :build_infos, inverse_of: :package
  has_many :pipelines, through: :build_infos, disable_joins: true
  has_one :debian_publication, inverse_of: :package, class_name: 'Packages::Debian::Publication'
  has_one :debian_distribution, through: :debian_publication, source: :distribution, inverse_of: :packages, class_name: 'Packages::Debian::ProjectDistribution'
  has_many :matching_package_protection_rules, -> (package) { where(package_type: package.package_type).for_package_name(package.name) }, through: :project, source: :package_protection_rules

  accepts_nested_attributes_for :conan_metadatum
  accepts_nested_attributes_for :debian_publication
  accepts_nested_attributes_for :maven_metadatum

  delegate :recipe, :recipe_path, to: :conan_metadatum, prefix: :conan
  delegate :codename, :suite, to: :debian_distribution, prefix: :debian_distribution
  delegate :target_sha, to: :composer_metadatum, prefix: :composer

  validates :project, presence: true
  validates :name, presence: true

  validates :name, format: { with: Gitlab::Regex.package_name_regex }, unless: -> { conan? || generic? || debian? }

  validates :name,
    uniqueness: {
      scope: %i[project_id version package_type],
      conditions: -> { not_pending_destruction }
    },
    unless: -> { pending_destruction? || conan? }

  validate :valid_conan_package_recipe, if: :conan?
  validate :valid_composer_global_name, if: :composer?
  validate :npm_package_already_taken, if: :npm?

  validates :name, format: { with: Gitlab::Regex.conan_recipe_component_regex }, if: :conan?
  validates :name, format: { with: Gitlab::Regex.generic_package_name_regex }, if: :generic?
  validates :name, format: { with: Gitlab::Regex.helm_package_regex }, if: :helm?
  validates :name, format: { with: Gitlab::Regex.npm_package_name_regex, message: Gitlab::Regex.npm_package_name_regex_message }, if: :npm?
  validates :name, format: { with: Gitlab::Regex.nuget_package_name_regex }, if: :nuget?
  validates :name, format: { with: Gitlab::Regex.terraform_module_package_name_regex }, if: :terraform_module?
  validates :name, format: { with: Gitlab::Regex.debian_package_name_regex }, if: :debian_package?
  validates :name, inclusion: { in: [Packages::Debian::INCOMING_PACKAGE_NAME] }, if: :debian_incoming?
  validates :version, format: { with: Gitlab::Regex.nuget_version_regex }, if: :nuget?
  validates :version, format: { with: Gitlab::Regex.conan_recipe_component_regex }, if: :conan?
  validates :version, format: { with: Gitlab::Regex.maven_version_regex }, if: -> { version? && maven? }
  validates :version, format: { with: Gitlab::Regex.pypi_version_regex }, if: :pypi?
  validates :version, format: { with: Gitlab::Regex.helm_version_regex }, if: :helm?
  validates :version, format: { with: Gitlab::Regex.semver_regex, message: Gitlab::Regex.semver_regex_message },
    if: -> { composer_tag_version? || npm? || terraform_module? }

  validates :version,
    presence: true,
    format: { with: Gitlab::Regex.generic_package_version_regex },
    if: :generic?
  validates :version,
    presence: true,
    format: { with: Gitlab::Regex.debian_version_regex },
    if: :debian_package?
  validate :forbidden_debian_changes, if: :debian?

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
  scope :without_version_like, -> (version) { where.not(arel_table[:version].matches(version)) }
  scope :with_package_type, ->(package_type) { where(package_type: package_type) }
  scope :without_package_type, ->(package_type) { where.not(package_type: package_type) }
  scope :displayable, -> { with_status(DISPLAYABLE_STATUSES) }
  scope :including_project_route, -> { includes(project: :route) }
  scope :including_project_namespace_route, -> { includes(project: { namespace: :route }) }
  scope :including_tags, -> { includes(:tags) }
  scope :including_dependency_links, -> { includes(dependency_links: :dependency) }
  scope :including_dependency_links_with_nuget_metadatum, -> { includes(dependency_links: [:dependency, :nuget_metadatum]) }

  scope :with_conan_channel, ->(package_channel) do
    joins(:conan_metadatum).where(packages_conan_metadata: { package_channel: package_channel })
  end
  scope :with_conan_username, ->(package_username) do
    joins(:conan_metadatum).where(packages_conan_metadata: { package_username: package_username })
  end

  scope :with_debian_codename, ->(codename) do
    joins(:debian_distribution).where(Packages::Debian::ProjectDistribution.table_name => { codename: codename })
  end
  scope :with_debian_codename_or_suite, ->(codename_or_suite) do
    joins(:debian_distribution).where(Packages::Debian::ProjectDistribution.table_name => { codename: codename_or_suite })
                               .or(where(Packages::Debian::ProjectDistribution.table_name => { suite: codename_or_suite }))
  end
  scope :preload_debian_file_metadata, -> { preload(package_files: :debian_file_metadatum) }
  scope :with_composer_target, -> (target) do
    includes(:composer_metadatum)
      .joins(:composer_metadatum)
      .where(Packages::Composer::Metadatum.table_name => { target_sha: target })
  end
  scope :preload_composer, -> { preload(:composer_metadatum) }
  scope :preload_npm_metadatum, -> { preload(:npm_metadatum) }
  scope :preload_nuget_metadatum, -> { preload(:nuget_metadatum) }
  scope :preload_pypi_metadatum, -> { preload(:pypi_metadatum) }
  scope :preload_conan_metadatum, -> { preload(:conan_metadatum) }

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
    keyset_order = keyset_pagination_order(join_class: Project, column_name: :path, direction: :asc)

    joins(:project).reorder(keyset_order)
  end

  scope :order_project_path_desc, -> do
    keyset_order = keyset_pagination_order(join_class: Project, column_name: :path, direction: :desc)

    joins(:project).reorder(keyset_order)
  end

  def self.inheritance_column = 'package_type'

  def self.inheritance_column_to_class_map = {
    ml_model: 'Packages::MlModel::Package',
    golang: 'Packages::Go::Package',
    rubygems: 'Packages::Rubygems::Package'
  }.freeze

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

  def self.debian_incoming_package!
    find_by!(name: Packages::Debian::INCOMING_PACKAGE_NAME, version: nil, package_type: :debian, status: :default)
  end

  def self.existing_debian_packages_with(name:, version:)
    debian.with_name(name)
          .with_version(version)
          .not_pending_destruction
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

  def self.keyset_pagination_order(join_class:, column_name:, direction: :asc)
    join_table = join_class.table_name
    asc_order_expression = join_class.arel_table[column_name].asc.nulls_last
    desc_order_expression = join_class.arel_table[column_name].desc.nulls_first
    order_direction = direction == :asc ? asc_order_expression : desc_order_expression
    reverse_order_direction = direction == :asc ? desc_order_expression : asc_order_expression
    arel_order_classes = ::Gitlab::Pagination::Keyset::ColumnOrderDefinition::AREL_ORDER_CLASSES.invert

    ::Gitlab::Pagination::Keyset::Order.build(
      [
        ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: "#{join_table}_#{column_name}",
          column_expression: join_class.arel_table[column_name],
          order_expression: order_direction,
          reversed_order_expression: reverse_order_direction,
          order_direction: direction,
          distinct: false,
          add_to_projections: true
        ),
        ::Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'id',
          order_expression: arel_order_classes[direction].new(Packages::Package.arel_table[:id]),
          add_to_projections: true
        )
      ])
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

  def debian_incoming?
    debian? && version.nil?
  end

  def debian_package?
    debian? && !version.nil?
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

  def composer_tag_version?
    composer? && !Gitlab::Regex.composer_dev_version_regex.match(version.to_s)
  end

  def valid_conan_package_recipe
    recipe_exists = project.packages
                           .conan
                           .includes(:conan_metadatum)
                           .not_pending_destruction
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
    package_exists = Packages::Package.default_scoped
                                      .composer
                                      .not_pending_destruction
                                      .with_name(name)
                                      .where.not(project_id: project_id)
                                      .exists?

    errors.add(:name, 'is already taken by another project') if package_exists
  end

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

  def forbidden_debian_changes
    return unless persisted?

    # Debian incoming
    if version_was.nil? || version.nil?
      errors.add(:version, _('cannot be changed')) if version_changed?
    end
  end
end
