# frozen_string_literal: true
module Packages
  module Rpm
    class RepositoryFile < ApplicationRecord
      include EachBatch
      include UpdateProjectStatistics
      include FileStoreMounter
      include Packages::Installable

      INSTALLABLE_STATUSES = [:default].freeze
      FILELISTS_FILENAME = 'filelists.xml'
      FILELISTS_SIZE_LIMITATION = 20.megabytes

      enum status: { default: 0, pending_destruction: 1, processing: 2, error: 3 }

      belongs_to :project, inverse_of: :rpm_repository_files

      validates :project, presence: true
      validates :file, presence: true
      validates :file_name, presence: true

      mount_file_store_uploader Packages::Rpm::RepositoryFileUploader

      update_project_statistics project_statistics_name: :packages_size

      def self.has_oversized_filelists?(project_id:)
        where(
          project_id: project_id,
          file_name: FILELISTS_FILENAME,
          size: [FILELISTS_SIZE_LIMITATION..]
        ).exists?
      end

      def self.installable_statuses
        INSTALLABLE_STATUSES
      end
    end
  end
end
