# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    LINKERS = [
      GemfileLinker,
      GemspecLinker,
      PackageJsonLinker,
      ComposerJsonLinker,
      PodfileLinker,
      PodspecLinker,
      PodspecJsonLinker,
      CartfileLinker,
      GodepsJsonLinker,
      RequirementsTxtLinker,
      CargoTomlLinker
    ].freeze

    def self.linker(blob_name)
      LINKERS.find { |linker| linker.support?(blob_name) }
    end

    def self.link(blob_name, plain_text, highlighted_text)
      linker = linker(blob_name)
      return highlighted_text unless linker

      linker.link(plain_text, highlighted_text)
    end
  end
end
