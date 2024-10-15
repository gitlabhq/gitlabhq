# frozen_string_literal: true

module Packages
  module Pypi
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :pypi_metadatum, inverse_of: :package, class_name: 'Packages::Pypi::Metadatum'

      validates :version, format: { with: Gitlab::Regex.pypi_version_regex }

      scope :with_normalized_pypi_name, ->(name) do
        where(
          "LOWER(regexp_replace(name, ?, '-', 'g')) = ?",
          Gitlab::Regex::Packages::PYPI_NORMALIZED_NAME_REGEX_STRING,
          name.downcase
        )
      end

      scope :preload_pypi_metadatum, -> { preload(:pypi_metadatum) }

      # As defined in PEP 503 https://peps.python.org/pep-0503/#normalized-names
      def normalized_pypi_name
        return name unless pypi?

        name.gsub(/#{Gitlab::Regex::Packages::PYPI_NORMALIZED_NAME_REGEX_STRING}/o, '-').downcase
      end
    end
  end
end
