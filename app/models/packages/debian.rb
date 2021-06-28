# frozen_string_literal: true

module Packages
  module Debian
    DISTRIBUTION_REGEX = %r{[a-z0-9][a-z0-9.-]*}i.freeze
    COMPONENT_REGEX = DISTRIBUTION_REGEX.freeze
    ARCHITECTURE_REGEX = %r{[a-z0-9][-a-z0-9]*}.freeze

    def self.table_name_prefix
      'packages_debian_'
    end
  end
end
