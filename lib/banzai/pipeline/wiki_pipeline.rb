# frozen_string_literal: true

module Banzai
  module Pipeline
    class WikiPipeline < FullPipeline
      def self.filters
        @filters ||= begin
          super.insert_before(Filter::ImageLazyLoadFilter, Filter::GollumTagsFilter)
               .insert_before(Filter::TaskListFilter, Filter::WikiLinkFilter)
        end
      end
    end
  end
end
