# frozen_string_literal: true

module Types
  module Packages
    module Cleanup
      class PolicyType < ::Types::BaseObject
        graphql_name 'PackagesCleanupPolicy'
        description 'A packages cleanup policy designed to keep only packages and packages assets that matter most'

        authorize :admin_package

        field :keep_n_duplicated_package_files,
          Types::Packages::Cleanup::KeepDuplicatedPackageFilesEnum,
          null: false,
          description: 'Number of duplicated package files to retain.'
        field :next_run_at,
          Types::TimeType,
          null: true,
          description: 'Next time that this packages cleanup policy will be executed.'
      end
    end
  end
end
