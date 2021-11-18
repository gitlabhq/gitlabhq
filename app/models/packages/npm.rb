# frozen_string_literal: true
module Packages
  module Npm
    # from "@scope/package-name" return "scope" or nil
    def self.scope_of(package_name)
      return unless package_name
      return unless package_name.starts_with?('@')
      return unless package_name.include?('/')

      package_name.match(Gitlab::Regex.npm_package_name_regex)&.captures&.first
    end

    def self.table_name_prefix
      'packages_npm_'
    end
  end
end
