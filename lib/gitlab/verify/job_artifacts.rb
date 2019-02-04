# frozen_string_literal: true

module Gitlab
  module Verify
    class JobArtifacts < BatchVerifier
      def name
        'Job artifacts'
      end

      def describe(object)
        "Job artifact: #{object.id}"
      end

      private

      def all_relation
        ::Ci::JobArtifact.all
      end

      def local?(artifact)
        artifact.local_store?
      end

      def expected_checksum(artifact)
        artifact.file_sha256
      end

      def actual_checksum(artifact)
        Digest::SHA256.file(artifact.file.path).hexdigest
      end

      def remote_object_exists?(artifact)
        artifact.file.file.exists?
      end
    end
  end
end
