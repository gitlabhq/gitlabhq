# frozen_string_literal: true
module Packages
  module Nuget
    TEMPORARY_PACKAGE_NAME = 'NuGet.Temporary.Package'

    def self.table_name_prefix
      'packages_nuget_'
    end
  end
end
