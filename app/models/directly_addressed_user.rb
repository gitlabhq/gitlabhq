# frozen_string_literal: true

class DirectlyAddressedUser
  class << self
    def reference_pattern
      User.reference_pattern
    end
  end
end
