# frozen_string_literal: true

module Banzai
  module Pipeline
    class CommitDescriptionPipeline < SingleLinePipeline
      def self.filters
        @filters ||= super.insert_after(Filter::ExternalLinkFilter, Filter::CommitTrailersFilter)
      end
    end
  end
end
