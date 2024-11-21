# frozen_string_literal: true
class Packages::PackageFile < ApplicationRecord
  include AfterCommitQueue
  include EachBatch
  include UpdateProjectStatistics
  include FileStoreMounter
  include Packages::Installable
  include Packages::Destructible

  INSTALLABLE_STATUSES = [:default].freeze
  ENCODED_SLASH = "%2F"

  delegate :project, :project_id, to: :package
  delegate :conan_file_type, to: :conan_file_metadatum
  delegate :file_type, :dsc?, :component, :architecture, :fields, to: :debian_file_metadatum, prefix: :debian
  delegate :channel, :metadata, to: :helm_file_metadatum, prefix: :helm

  enum status: { default: 0, pending_destruction: 1, processing: 2, error: 3 }

  belongs_to :package

  # used to move the linked file within object storage
  attribute :new_file_path, default: nil

  has_one :conan_file_metadatum, inverse_of: :package_file, class_name: 'Packages::Conan::FileMetadatum'
  has_many :package_file_build_infos, inverse_of: :package_file, class_name: 'Packages::PackageFileBuildInfo'
  has_many :pipelines, through: :package_file_build_infos, disable_joins: true
  has_one :debian_file_metadatum, inverse_of: :package_file, class_name: 'Packages::Debian::FileMetadatum'
  has_one :helm_file_metadatum, inverse_of: :package_file, class_name: 'Packages::Helm::FileMetadatum'

  accepts_nested_attributes_for :conan_file_metadatum
  accepts_nested_attributes_for :debian_file_metadatum
  accepts_nested_attributes_for :helm_file_metadatum

  validates :package, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  validates :file_name, uniqueness: { scope: :package }, if: -> { !pending_destruction? && package&.pypi? }
  validates :file_sha256, format: { with: Gitlab::Regex.sha256_regex }, if: -> { package&.pypi? }, allow_nil: true

  scope :recent, -> { order(id: :desc) }
  scope :limit_recent, ->(limit) { recent.limit(limit) }
  scope :for_package_ids, ->(ids) { where(package_id: ids) }
  scope :with_file_name, ->(file_name) { where(file_name: file_name) }
  scope :with_file_name_like, ->(file_name) { where(arel_table[:file_name].matches(file_name)) }
  scope :with_files_stored_locally, -> { where(file_store: ::Packages::PackageFileUploader::Store::LOCAL) }
  scope :with_format, ->(format) { where(::Packages::PackageFile.arel_table[:file_name].matches("%.#{format}")) }
  scope :with_nuget_format, -> { where("reverse(split_part(reverse(packages_package_files.file_name), '.', 1)) = :format", format: Packages::Nuget::FORMAT) }

  scope :preload_package, -> { preload(:package) }
  scope :preload_pipelines, -> { preload(pipelines: :user) }
  scope :preload_conan_file_metadata, -> { preload(:conan_file_metadatum) }
  scope :preload_debian_file_metadata, -> { preload(:debian_file_metadatum) }
  scope :preload_helm_file_metadata, -> { preload(:helm_file_metadatum) }
  scope :order_id_asc, -> { order(id: :asc) }

  scope :for_rubygem_with_file_name, ->(project, file_name) do
    joins(:package).merge(project.packages.rubygems).with_file_name(file_name)
  end

  scope :for_helm_with_channel, ->(project, channel) do
    joins(:package)
      .merge(project.packages.helm.installable)
      .joins(:helm_file_metadatum)
      .where(packages_helm_file_metadata: { channel: channel })
      .installable
  end

  scope :with_conan_file_type, ->(file_type) do
    joins(:conan_file_metadatum)
      .where(packages_conan_file_metadata: { conan_file_type: ::Packages::Conan::FileMetadatum.conan_file_types[file_type] })
  end

  scope :with_debian_file_type, ->(file_type) do
    joins(:debian_file_metadatum)
      .where(packages_debian_file_metadata: { file_type: ::Packages::Debian::FileMetadatum.file_types[file_type] })
  end

  scope :with_debian_component_name, ->(component_name) do
    joins(:debian_file_metadatum)
      .where(packages_debian_file_metadata: { component: component_name })
  end

  scope :with_debian_architecture_name, ->(architecture_name) do
    joins(:debian_file_metadatum)
      .where(packages_debian_file_metadata: { architecture: architecture_name })
  end

  scope :with_debian_unknown_since, ->(updated_before) do
    file_metadata = Packages::Debian::FileMetadatum.with_file_type(:unknown)
                                                   .updated_before(updated_before)
                                                   .where('packages_package_files.id = packages_debian_file_metadata.package_file_id')
    where('EXISTS (?)', file_metadata.select(1))
  end

  scope :with_conan_package_reference, ->(conan_package_reference) do
    joins(:conan_file_metadatum)
      .where(packages_conan_file_metadata: { conan_package_reference: conan_package_reference })
  end

  def self.most_recent!
    recent.first!
  end

  mount_file_store_uploader Packages::PackageFileUploader

  update_project_statistics project_statistics_name: :packages_size

  before_save :update_size_from_file

  # if a new_file_path is provided, we need
  # * disable the remove_previously_stored_file callback so that carrierwave doesn't take care of the file
  # * enable a new after_commit callback that will move the file in object storage
  skip_callback :commit, :after, :remove_previously_stored_file, if: :execute_move_in_object_storage?
  after_commit :move_in_object_storage, if: :execute_move_in_object_storage?

  # Returns the most recent installable package file for *each* of the given packages.
  # The order is not guaranteed.
  def self.most_recent_for(packages, extra_join: nil, extra_where: nil)
    cte_name = :packages_cte
    cte = Gitlab::SQL::CTE.new(cte_name, packages.select(:id))

    package_files = ::Packages::PackageFile.installable
                                           .limit_recent(1)
                                           .where(arel_table[:package_id].eq(Arel.sql("#{cte_name}.id")))

    package_files = package_files.joins(extra_join) if extra_join
    package_files = package_files.where(extra_where) if extra_where

    query = select('finder.*')
              .from([Arel.sql(cte_name.to_s), package_files.arel.lateral.as('finder')])

    query.with(cte.to_arel)
  end

  def self.installable_statuses
    INSTALLABLE_STATUSES
  end

  def download_path
    Gitlab::Routing.url_helpers.download_project_package_file_path(project, self)
  end

  def file_name_for_download
    file_name.split(ENCODED_SLASH)[-1]
  end

  private

  def update_size_from_file
    self.size ||= file.size
  end

  def execute_move_in_object_storage?
    !file.file_storage? && new_file_path?
  end

  def move_in_object_storage
    carrierwave_file = file.file

    carrierwave_file.copy_to(new_file_path)
    carrierwave_file.delete
  end
end

Packages::PackageFile.prepend_mod_with('Packages::PackageFile')
