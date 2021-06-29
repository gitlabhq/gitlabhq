# frozen_string_literal: true
class Packages::PackageFile < ApplicationRecord
  include UpdateProjectStatistics
  include FileStoreMounter

  delegate :project, :project_id, to: :package
  delegate :conan_file_type, to: :conan_file_metadatum
  delegate :file_type, :component, :architecture, :fields, to: :debian_file_metadatum, prefix: :debian
  delegate :channel, :metadata, to: :helm_file_metadatum, prefix: :helm

  belongs_to :package

  has_one :conan_file_metadatum, inverse_of: :package_file, class_name: 'Packages::Conan::FileMetadatum'
  has_many :package_file_build_infos, inverse_of: :package_file, class_name: 'Packages::PackageFileBuildInfo'
  has_many :pipelines, through: :package_file_build_infos
  has_one :debian_file_metadatum, inverse_of: :package_file, class_name: 'Packages::Debian::FileMetadatum'
  has_one :helm_file_metadatum, inverse_of: :package_file, class_name: 'Packages::Helm::FileMetadatum'

  accepts_nested_attributes_for :conan_file_metadatum
  accepts_nested_attributes_for :debian_file_metadatum
  accepts_nested_attributes_for :helm_file_metadatum

  validates :package, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  validates :file_name, uniqueness: { scope: :package }, if: -> { package&.pypi? }

  scope :recent, -> { order(id: :desc) }
  scope :limit_recent, ->(limit) { recent.limit(limit) }
  scope :for_package_ids, ->(ids) { where(package_id: ids) }
  scope :with_file_name, ->(file_name) { where(file_name: file_name) }
  scope :with_file_name_like, ->(file_name) { where(arel_table[:file_name].matches(file_name)) }
  scope :with_files_stored_locally, -> { where(file_store: ::Packages::PackageFileUploader::Store::LOCAL) }
  scope :with_format, ->(format) { where(::Packages::PackageFile.arel_table[:file_name].matches("%.#{format}")) }
  scope :preload_conan_file_metadata, -> { preload(:conan_file_metadatum) }
  scope :preload_debian_file_metadata, -> { preload(:debian_file_metadatum) }
  scope :preload_helm_file_metadata, -> { preload(:helm_file_metadatum) }

  scope :for_rubygem_with_file_name, ->(project, file_name) do
    joins(:package).merge(project.packages.rubygems).with_file_name(file_name)
  end

  scope :for_helm_with_channel, ->(project, channel) do
    joins(:package).merge(project.packages.helm.installable)
                   .joins(:helm_file_metadatum)
                   .where(packages_helm_file_metadata: { channel: channel })
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

  scope :with_conan_package_reference, ->(conan_package_reference) do
    joins(:conan_file_metadatum)
      .where(packages_conan_file_metadata: { conan_package_reference: conan_package_reference })
  end

  mount_file_store_uploader Packages::PackageFileUploader

  update_project_statistics project_statistics_name: :packages_size

  before_save :update_size_from_file

  def download_path
    Gitlab::Routing.url_helpers.download_project_package_file_path(project, self)
  end

  private

  def update_size_from_file
    self.size ||= file.size
  end
end

Packages::PackageFile.prepend_mod_with('Packages::PackageFile')
