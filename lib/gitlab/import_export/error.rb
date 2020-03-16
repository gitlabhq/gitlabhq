# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Error < StandardError
      def self.permission_error(user, importable)
        self.new(
          "User with ID: %s does not have required permissions for %s: %s with ID: %s" %
          [user.id, importable.class.name, importable.name, importable.id]
        )
      end
    end
  end
end
