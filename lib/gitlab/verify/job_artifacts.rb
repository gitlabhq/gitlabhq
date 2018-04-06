module Gitlab
  module Verify
    class JobArtifacts < BatchVerifier
      prepend ::EE::Gitlab::Verify::JobArtifacts

      def name
        'Job artifacts'
      end

      def describe(object)
        "Job artifact: #{object.id}"
      end

      private

      def relation
        ::Ci::JobArtifact.all
      end

      def expected_checksum(artifact)
        artifact.file_sha256
      end

      def actual_checksum(artifact)
        Digest::SHA256.file(artifact.file.path).hexdigest
      end
    end
  end
end
