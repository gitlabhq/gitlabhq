# frozen_string_literal: true

module Gitlab
  module Cleanup
    module ObjectStorageCleanerMapping
      # Maps buckets to their respective model classes and cleaners
      MAPPING = {
        artifacts: ::Gitlab::Cleanup::RemoteArtifacts,
        ci_secure_files: ::Gitlab::Cleanup::RemoteCiSecureFiles,
        uploads: ::Gitlab::Cleanup::RemoteUploads
      }.freeze

      def self.buckets
        MAPPING.keys
      end

      def self.cleaner_class_for(bucket)
        MAPPING[bucket]
      end
    end
  end
end
