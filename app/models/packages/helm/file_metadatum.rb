# frozen_string_literal: true

module Packages
  module Helm
    class FileMetadatum < ApplicationRecord
      self.primary_key = :package_file_id

      belongs_to :package_file, inverse_of: :helm_file_metadatum

      validates :package_file, presence: true
      validate :valid_helm_package_type

      validates :channel,
        presence: true,
        length: { maximum: 63 },
        format: { with: Gitlab::Regex.helm_channel_regex }

      validates :metadata,
        json_schema: { filename: "helm_metadata" }

      private

      def valid_helm_package_type
        return if package_file&.package&.helm?

        errors.add(:package_file, _('Package type must be Helm'))
      end
    end
  end
end
