# frozen_string_literal: true

module Packages
  module Pypi
    class FileMetadatum < ApplicationRecord
      self.primary_key = :package_file_id

      belongs_to :package_file, inverse_of: :pypi_file_metadatum, optional: false
      belongs_to :project, optional: false

      validates :required_python, length: { maximum: Packages::Pypi::Metadatum::MAX_REQUIRED_PYTHON_LENGTH },
        allow_nil: false
      validate :valid_pypi_package_type

      private

      def valid_pypi_package_type
        return if package_file&.package&.pypi?

        errors.add(:package_file, _('Package type must be PyPI'))
      end
    end
  end
end
