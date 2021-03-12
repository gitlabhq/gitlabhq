# frozen_string_literal: true
module Packages
  module Rubygems
    TEMPORARY_PACKAGE_NAME = 'Gem.Temporary.Package'

    def self.table_name_prefix
      'packages_rubygems_'
    end
  end
end
