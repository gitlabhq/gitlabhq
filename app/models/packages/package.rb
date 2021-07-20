# frozen_string_literal: true
class Packages::Package < ApplicationRecord
  include Sortable
  include Gitlab::SQL::Pattern
  include UsageStatistics
  include Gitlab::Utils::StrongMemoize

  DISPLAYABLE_STATUSES = [:default, :error].freeze
  INSTALLABLE_STATUSES = [:default].freeze

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
    terraform_module: 12
  }

  enum status: { default: 0, hidden: 1, processing: 2, error: 3 }

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
  has_one :rubygems_metadatum, inverse_of: :package, class_name: 'Packages::Rubygems::Metadatum'
  has_many :build_infos, inverse_of: :package
  has_many :pipelines, through: :build_infos
  has_one :debian_publication, inverse_of: :package, class_name: 'Packages::Debian::Publication'
  has_one :debian_distribution, through: :debian_publication, source: :distribution, inverse_of: :packages, class_name: 'Packages::Debian::ProjectDistribution'

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
    uniqueness: { scope: %i[project_id version package_type] }, unless: -> { conan? || debian_package? }
  validate :unique_debian_package_name, if: :debian_package?

  validate :valid_conan_package_recipe, if: :conan?
  validate :valid_composer_global_name, if: :composer?
  validate :package_already_taken, if: :npm?
  validates :name, format: { with: Gitlab::Regex.conan_recipe_component_regex }, if: :conan?
  validates :name, format: { with: Gitlab::Regex.generic_package_name_regex }, if: :generic?
  validates :name, format: { with: Gitlab::Regex.helm_package_regex }, if: :helm?
  validates :name, format: { with: Gitlab::Regex.npm_package_name_regex }, if: :npm?
  validates :name, format: { with: Gitlab::Regex.nuget_package_name_regex }, if: :nuget?
  validates :name, format: { with: Gitlab::Regex.terraform_module_package_name_regex }, if: :terraform_module?
  validates :name, format: { with: Gitlab::Regex.debian_package_name_regex }, if: :debian_package?
  validates :name, inclusion: { in: %w[incoming] }, if: :debian_incoming?
  validates :version, format: { with: Gitlab::Regex.nuget_version_regex }, if: :nuget?
  validates :version, format: { with: Gitlab::Regex.conan_recipe_component_regex }, if: :conan?
  validates :version, format: { with: Gitlab::Regex.maven_version_regex }, if: -> { version? && maven? }
  validates :version, format: { with: Gitlab::Regex.pypi_version_regex }, if: :pypi?
  validates :version, format: { with: Gitlab::Regex.prefixed_semver_regex }, if: :golang?
  validates :version, format: { with: Gitlab::Regex.helm_version_regex }, if: :helm?
  validates :version, format: { with: Gitlab::Regex.semver_regex }, if: -> { composer_tag_version? || npm? || terraform_module? }

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
  scope :with_normalized_pypi_name, ->(name) { where("LOWER(regexp_replace(name, '[-_.]+', '-', 'g')) = ?", name.downcase) }
  scope :search_by_name, ->(query) { fuzzy_search(query, [:name], use_minimum_char_limit: false) }
  scope :with_version, ->(version) { where(version: version) }
  scope :without_version_like, -> (version) { where.not(arel_table[:version].matches(version)) }
  scope :with_package_type, ->(package_type) { where(package_type: package_type) }
  scope :without_package_type, ->(package_type) { where.not(package_type: package_type) }
  scope :with_status, ->(status) { where(status: status) }
  scope :displayable, -> { with_status(DISPLAYABLE_STATUSES) }
  scope :installable, -> { with_status(INSTALLABLE_STATUSES) }
  scope :including_build_info, -> { includes(pipelines: :user) }
  scope :including_project_route, -> { includes(project: { namespace: :route }) }
  scope :including_tags, -> { includes(:tags) }

  scope :with_conan_channel, ->(package_channel) do
    joins(:conan_metadatum).where(packages_conan_metadata: { package_channel: package_channel })
  end
  scope :with_conan_username, ->(package_username) do
    joins(:conan_metadatum).where(packages_conan_metadata: { package_username: package_username })
  end

  scope :with_debian_codename, -> (codename) do
    debian
      .joins(:debian_distribution)
      .where(Packages::Debian::ProjectDistribution.table_name => { codename: codename })
  end
  scope :preload_debian_file_metadata, -> { preload(package_files: :debian_file_metadatum) }
  scope :with_composer_target, -> (target) do
    includes(:composer_metadatum)
      .joins(:composer_metadatum)
      .where(Packages::Composer::Metadatum.table_name => { target_sha: target })
  end
  scope :preload_composer, -> { preload(:composer_metadatum) }

  scope :without_nuget_temporary_name, -> { where.not(name: Packages::Nuget::TEMPORARY_PACKAGE_NAME) }

  scope :has_version, -> { where.not(version: nil) }
  scope :preload_files, -> { preload(:package_files) }
  scope :last_of_each_version, -> { where(id: all.select('MAX(id) AS id').group(:version)) }
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

  def self.keyset_pagination_order(join_class:, column_name:, direction: :asc)
    join_table = join_class.table_name
    asc_order_expression = Gitlab::Database.nulls_last_order("#{join_table}.#{column_name}", :asc)
    desc_order_expression = Gitlab::Database.nulls_first_order("#{join_table}.#{column_name}", :desc)
    order_direction = direction == :asc ? asc_order_expression : desc_order_expression
    reverse_order_direction = direction == :asc ? desc_order_expression : asc_order_expression
    arel_order_classes = ::Gitlab::Pagination::Keyset::ColumnOrderDefinition::AREL_ORDER_CLASSES.invert

    ::Gitlab::Pagination::Keyset::Order.build([
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
    strong_memoize(:package_settings) do
      project.namespace.package_settings
    end
  end

  def sync_maven_metadata(user)
    return unless maven? && version? && user

    ::Packages::Maven::Metadata::SyncWorker.perform_async(user.id, project.id, name)
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

  def package_already_taken
    return unless project

    if project.package_already_taken?(name)
      errors.add(:base, _('Package already exists'))
    end
  end

  def unique_debian_package_name
    return unless debian_publication&.distribution

    package_exists = debian_publication.distribution.packages
                            .with_name(name)
                            .with_version(version)
                            .id_not_in(id)
                            .exists?

    errors.add(:base, _('Debian package already exists in Distribution')) if package_exists
  end

  def forbidden_debian_changes
    return unless persisted?

    # Debian incoming
    if version_was.nil? || version.nil?
      errors.add(:version, _('cannot be changed')) if version_changed?
    end
  end
end
