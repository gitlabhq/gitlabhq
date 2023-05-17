# frozen_string_literal: true

module Packages
  module Debian
    TEMPORARY_PACKAGE_NAME = 'debian-temporary-package'

    DISTRIBUTION_REGEX = %r{[a-z0-9][a-z0-9.-]*}i.freeze
    COMPONENT_REGEX = DISTRIBUTION_REGEX.freeze
    ARCHITECTURE_REGEX = %r{[a-z0-9][-a-z0-9]*}.freeze

    LETTER_REGEX = %r{(lib)?[a-z0-9]}.freeze

    EMPTY_FILE_SHA256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'.freeze

    INCOMING_PACKAGE_NAME = 'incoming'

    def self.table_name_prefix
      'packages_debian_'
    end
  end
end
