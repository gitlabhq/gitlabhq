# frozen_string_literal: true

module Packages
  module Helm
    TEMPORARY_PACKAGE_NAME = 'Helm.Temporary.Package'

    def self.table_name_prefix
      'packages_helm_'
    end
  end
end
