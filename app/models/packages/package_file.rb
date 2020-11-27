# frozen_string_literal: true
class Packages::PackageFile < ApplicationRecord
  include UpdateProjectStatistics
  include FileStoreMounter

  delegate :project, :project_id, to: :package
  delegate :conan_file_type, to: :conan_file_metadatum

  belongs_to :package

  has_one :conan_file_metadatum, inverse_of: :package_file, class_name: 'Packages::Conan::FileMetadatum'
  has_many :package_file_build_infos, inverse_of: :package_file, class_name: 'Packages::PackageFileBuildInfo'
  has_many :pipelines, through: :package_file_build_infos

  accepts_nested_attributes_for :conan_file_metadatum

  validates :package, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  validates :file_name, uniqueness: { scope: :package }, if: -> { package&.pypi? }

  scope :recent, -> { order(id: :desc) }
  scope :with_file_name, ->(file_name) { where(file_name: file_name) }
  scope :with_file_name_like, ->(file_name) { where(arel_table[:file_name].matches(file_name)) }
  scope :with_files_stored_locally, -> { where(file_store: ::Packages::PackageFileUploader::Store::LOCAL) }
  scope :preload_conan_file_metadata, -> { preload(:conan_file_metadatum) }

  scope :with_conan_file_type, ->(file_type) do
    joins(:conan_file_metadatum)
      .where(packages_conan_file_metadata: { conan_file_type: ::Packages::Conan::FileMetadatum.conan_file_types[file_type] })
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

  def local?
    file_store == ::Packages::PackageFileUploader::Store::LOCAL
  end

  private

  def update_size_from_file
    self.size ||= file.size
  end
end

Packages::PackageFile.prepend_if_ee('EE::Packages::PackageFile')
