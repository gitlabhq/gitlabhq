# frozen_string_literal: true

module Banzai
  module Pipeline
    class OrgMarkupPipeline < MarkupPipeline
      def self.filters
        @filters ||= super.dup.insert_after(Filter::AssetProxyFilter, Filter::AutolinkFilter)
      end
    end
  end
end
