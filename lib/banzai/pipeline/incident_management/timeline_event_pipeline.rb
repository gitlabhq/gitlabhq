# frozen_string_literal: true

module Banzai
  module Pipeline
    module IncidentManagement
      class TimelineEventPipeline < PlainMarkdownPipeline
        ALLOWLIST = Banzai::Filter::SanitizationFilter::LIMITED.deep_dup.merge(
          elements: %w[p b i strong em pre code a img]
        ).freeze

        def self.filters
          @filters ||= FilterArray[
            *super,
            Filter::SanitizationFilter,
            Filter::SanitizeLinkFilter,
            *Banzai::Pipeline::GfmPipeline.reference_filters,
            Filter::EmojiFilter,
            Filter::ExternalLinkFilter,
            Filter::ImageLinkFilter
          ]
        end

        def self.transform_context(context)
          Filter::AssetProxyFilter.transform_context(context).merge(
            only_path: true,
            no_sourcepos: true,
            allowlist: ALLOWLIST,
            link_replaces_image: true
          )
        end
      end
    end
  end
end
