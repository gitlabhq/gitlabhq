# frozen_string_literal: true

module Packages
  module Debian
    class FileMetadatum < ApplicationRecord
      include UpdatedAtFilterable

      self.primary_key = :package_file_id

      belongs_to :package_file, inverse_of: :debian_file_metadatum

      validates :package_file, presence: true
      validate :valid_debian_package_type

      enum file_type: {
        unknown: 1, source: 2, dsc: 3, deb: 4, udeb: 5, buildinfo: 6, changes: 7, ddeb: 8
      }

      validates :file_type, presence: true
      validates :file_type, inclusion: { in: %w[unknown] },
        if: -> { package_file&.package&.incoming? || package_file&.package&.processing? }
      validates :file_type,
        inclusion: { in: %w[source dsc deb udeb buildinfo changes ddeb] },
        if: -> { !package_file&.package&.incoming? && !package_file&.package&.processing? }

      validates :component,
        presence: true,
        format: { with: Gitlab::Regex.debian_component_regex },
        if: :requires_component?
      validates :component, absence: true, unless: :requires_component?

      validates :architecture,
        presence: true,
        format: { with: Gitlab::Regex.debian_architecture_regex },
        if: :requires_architecture?
      validates :architecture, absence: true, unless: :requires_architecture?

      validates :fields,
        presence: true,
        json_schema: { filename: "debian_fields" },
        if: :requires_fields?
      validates :fields, absence: true, unless: :requires_fields?

      scope :with_file_type, ->(file_type) do
        where(file_type: file_type)
      end

      private

      def valid_debian_package_type
        return if package_file&.package&.debian?

        errors.add(:package_file, _('Package type must be Debian'))
      end

      def requires_architecture?
        deb? || udeb? || ddeb?
      end

      def requires_component?
        source? || dsc? || requires_architecture? || buildinfo?
      end

      def requires_fields?
        dsc? || requires_architecture? || buildinfo? || changes?
      end
    end
  end
end
