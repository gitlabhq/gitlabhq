# frozen_string_literal: true
module Packages
  DuplicatePackageError = Class.new(StandardError)

  def self.table_name_prefix
    'packages_'
  end
end
