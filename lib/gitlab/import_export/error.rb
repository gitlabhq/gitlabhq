# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Error < StandardError
      def self.permission_error(user, object)
        self.new(
          "User with ID: %s does not have required permissions for %s: %s with ID: %s" %
            [user.id, object.class.name, object.name, object.id]
        )
      end

      def self.unsupported_object_type_error
        self.new('Unknown object type')
      end

      def self.file_compression_error(error)
        self.new(format('File compression or decompression failed. %{error}', error: error))
      end

      def self.incompatible_import_file_error
        self.new('The import file is incompatible')
      end
    end
  end
end
