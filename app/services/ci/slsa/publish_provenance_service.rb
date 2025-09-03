# frozen_string_literal: true

require 'digest'

module Ci
  module Slsa
    class PublishProvenanceService < ::BaseService
      HASH_READ_CHUNK_SIZE = 1.megabyte

      def initialize(build)
        @build = build
      end

      def execute
        return ServiceResponse.error(message: "Unable to find build") unless @build

        reader = SupplyChain::ArtifactsReader.new(@build)

        reader.files do |artifact_path, file_input_stream|
          hash = hash(file_input_stream)
          Gitlab::AppJsonLogger.info(class: self.class.name, message: "Performing attestation for artifact",
            hash: hash, path: artifact_path)

          # TODO: sign statement using `cosign`.
        end

        ServiceResponse.success(message: "OK")
      end

      def hash(file_input_stream)
        sha = Digest::SHA256.new
        sha << file_input_stream.read(HASH_READ_CHUNK_SIZE) until file_input_stream.eof?
        sha.hexdigest
      end
    end
  end
end

Ci::Slsa::PublishProvenanceService.prepend_mod
