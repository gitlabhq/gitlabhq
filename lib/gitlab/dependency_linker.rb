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
      CargoTomlLinker,
      GoModLinker,
      GoSumLinker
    ].freeze

    def self.linker(blob_name)
      LINKERS.find { |linker| linker.support?(blob_name) }
    end

    def self.link(blob_name, plain_text, highlighted_text, used_on: :blob)
      linker = linker(blob_name)
      return highlighted_text unless linker

      usage_counter.increment(used_on: used_on)
      linker.link(plain_text, highlighted_text)
    end

    def self.usage_counter
      Gitlab::Metrics.counter(
        :dependency_linker_usage,
        'The number of times dependency linker is used'
      )
    end
  end
end
