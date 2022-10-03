# frozen_string_literal: true
module Packages
  module Rpm
    class RepositoryFile < ApplicationRecord
      include EachBatch
      include UpdateProjectStatistics
      include FileStoreMounter
      include Packages::Installable

      INSTALLABLE_STATUSES = [:default].freeze

      enum status: { default: 0, pending_destruction: 1, processing: 2, error: 3 }

      belongs_to :project, inverse_of: :repository_files

      validates :project, presence: true
      validates :file, presence: true
      validates :file_name, presence: true

      mount_file_store_uploader Packages::Rpm::RepositoryFileUploader

      update_project_statistics project_statistics_name: :packages_size
    end
  end
end
