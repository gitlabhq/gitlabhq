# frozen_string_literal: true

module ContainerRegistry
  class ImageManifest
    attr_reader :tag, :digest, :media_type, :size
    attr_accessor :platform

    def initialize(tag:, digest:, media_type:, size:)
      @tag = tag
      @digest = digest
      @media_type = media_type
      @size = size
    end
  end
end
