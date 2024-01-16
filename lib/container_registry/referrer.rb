# frozen_string_literal: true

module ContainerRegistry
  class Referrer
    attr_reader :artifact_type, :digest, :tag

    def initialize(artifact_type, digest, tag)
      @artifact_type = artifact_type
      @digest = digest
      @tag = tag
    end
  end
end
