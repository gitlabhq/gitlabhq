# frozen_string_literal: true

module Types
  module Packages
    module Cleanup
      class KeepDuplicatedPackageFilesEnum < BaseEnum
        graphql_name 'PackagesCleanupKeepDuplicatedPackageFilesEnum'

        OPTIONS_MAPPING = {
          'all' => 'ALL_PACKAGE_FILES',
          '1' => 'ONE_PACKAGE_FILE',
          '10' => 'TEN_PACKAGE_FILES',
          '20' => 'TWENTY_PACKAGE_FILES',
          '30' => 'THIRTY_PACKAGE_FILES',
          '40' => 'FORTY_PACKAGE_FILES',
          '50' => 'FIFTY_PACKAGE_FILES'
        }.freeze

        ::Packages::Cleanup::Policy::KEEP_N_DUPLICATED_PACKAGE_FILES_VALUES.each do |keep_value|
          value OPTIONS_MAPPING[keep_value], value: keep_value, description: "Value to keep #{keep_value} package files"
        end
      end
    end
  end
end
