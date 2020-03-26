# frozen_string_literal: true

# As of v3.1.0, attr_encrypted is not thread-safe because all instances share the same `encrypted_attributes`
# This was fixed in https://github.com/attr-encrypted/attr_encrypted/commit/d4ca0e2073ca6ba5035997ce25f7fc0b4bfbe39e
# but no release was made after that so we have to patch it ourselves here

module AttrEncrypted
  module InstanceMethods
    def encrypted_attributes
      @encrypted_attributes ||= begin
        duplicated = {}
        self.class.encrypted_attributes.map { |key, value| duplicated[key] = value.dup }
        duplicated
      end
    end
  end
end
