# frozen_string_literal: true

module Gitlab
  module Verify
    class CiSecureFiles < BatchVerifier
      def name
        'CI Secure Files'
      end

      def describe(object)
        "SecureFile: #{object.id}"
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def all_relation
        ::Ci::SecureFile.all
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def local?(secure_file)
        secure_file.local?
      end

      def expected_checksum(secure_file)
        secure_file.checksum
      end

      def actual_checksum(secure_file)
        Digest::SHA256.hexdigest(secure_file.file.read)
      end

      def remote_object_exists?(secure_file)
        secure_file.file.file.exists?
      end
    end
  end
end
