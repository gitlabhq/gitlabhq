# frozen_string_literal: true

class BackfillNugetTemporaryPackagesToProcessingStatus < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  class Package < ActiveRecord::Base
    include EachBatch

    self.table_name = 'packages_packages'

    scope :nuget_temporary_packages, -> do
      # 4 is nuget package type, 0 is default status
      where(package_type: 4, name: 'NuGet.Temporary.Package', status: 0)
    end
  end

  def up
    Package.nuget_temporary_packages.each_batch(of: 100) do |batch|
      # 2 is processing status
      batch.update_all(status: 2)
    end
  end

  def down
    # no-op
  end
end
