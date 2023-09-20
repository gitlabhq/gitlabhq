# frozen_string_literal: true

module Packages
  module Debian
    TEMPORARY_PACKAGE_NAME = 'debian-temporary-package'

    DISTRIBUTION_REGEX = %r{[a-z0-9][a-z0-9.-]*}i
    COMPONENT_REGEX = DISTRIBUTION_REGEX.freeze
    ARCHITECTURE_REGEX = %r{[a-z0-9][-a-z0-9]*}

    LETTER_REGEX = %r{(lib)?[a-z0-9]}

    EMPTY_FILE_SHA256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'

    INCOMING_PACKAGE_NAME = 'incoming'

    def self.table_name_prefix
      'packages_debian_'
    end
  end
end
