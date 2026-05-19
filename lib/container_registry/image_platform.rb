# frozen_string_literal: true

module ContainerRegistry
  class ImagePlatform
    attr_reader :parent, :architecture, :os, :os_version, :variant

    def self.from_hash(parent, platform_hash)
      return unless platform_hash

      new(parent, **platform_hash.slice('architecture', 'os', 'os_version', 'variant').transform_keys(&:to_sym))
    end

    def initialize(parent, architecture: nil, os: nil, os_version: nil, variant: nil)
      @parent = parent
      @architecture = architecture
      @os = os
      @os_version = os_version
      @variant = variant
    end
  end
end
