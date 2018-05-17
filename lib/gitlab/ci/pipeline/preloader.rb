# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      # Class for preloading data associated with pipelines such as commit
      # authors.
      module Preloader
        def self.preload(pipelines)
          # This ensures that all the pipeline commits are eager loaded before we
          # start using them.
          pipelines.each(&:commit)

          pipelines.each do |pipeline|
            # This preloads the author of every commit. We're using "lazy_author"
            # here since "author" immediately loads the data on the first call.
            pipeline.commit.try(:lazy_author)

            # This preloads the number of warnings for every pipeline, ensuring
            # that Ci::Pipeline#has_warnings? doesn't execute any additional
            # queries.
            pipeline.number_of_warnings
          end
        end
      end
    end
  end
end
