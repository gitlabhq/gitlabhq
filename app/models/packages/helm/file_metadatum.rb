# frozen_string_literal: true

module Packages
  module Helm
    class FileMetadatum < ApplicationRecord
      self.primary_key = :package_file_id

      belongs_to :package_file, inverse_of: :helm_file_metadatum
      belongs_to :project

      validates :package_file, presence: true
      validate :valid_helm_package_type

      validates :channel,
        presence: true,
        length: { maximum: 255 },
        format: { with: Gitlab::Regex.helm_channel_regex }

      validates :metadata,
        json_schema: { filename: "helm_metadata" }

      scope :select_distinct_channel_and_project, -> { select(:channel, :project_id).distinct }
      scope :for_package_files, ->(package_files) { where(package_file: package_files) }
      scope :preload_projects, -> { preload(:project) }

      private

      def valid_helm_package_type
        return if package_file&.package&.helm?

        errors.add(:package_file, _('Package type must be Helm'))
      end
    end
  end
end
