module Banzai
  module Pipeline
    class CommitDescriptionPipeline < SingleLinePipeline
      def self.filters
        @filters ||= super.concat FilterArray[
          Filter::CommitTrailersFilter,
        ]
      end
    end
  end
end
