# frozen_string_literal: true

require 'licensee/license'

module Licensee
  module LicensePatch
    # Patch from https://github.com/licensee/licensee/pull/589
    def ==(other)
      other.is_a?(self.class) && key == other.key
    end
  end

  License.prepend LicensePatch
end
