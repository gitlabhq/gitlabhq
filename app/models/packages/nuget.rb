# frozen_string_literal: true
module Packages
  module Nuget
    TEMPORARY_PACKAGE_NAME = 'NuGet.Temporary.Package'
    TEMPORARY_SYMBOL_PACKAGE_NAME = 'NuGet.Temporary.SymbolPackage'
    FORMAT = 'nupkg'

    def self.table_name_prefix
      'packages_nuget_'
    end
  end
end
