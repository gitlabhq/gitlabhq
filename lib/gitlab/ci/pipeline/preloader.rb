# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      # Class for preloading data associated with pipelines such as commit
      # authors.
      class Preloader
        def self.preload!(pipelines)
          pipelines.each do |pipeline|
            self.new(pipeline).tap do |preloader|
              preloader.preload_commits
              preloader.preload_pipeline_warnings
              preloader.preload_stages_warnings
            end
          end
        end

        def initialize(pipeline)
          @pipeline = pipeline
        end

        def preload_commits
          # This ensures that all the pipeline commits are eager loaded before we
          # start using them.
          #
          # This also preloads the author of every commit. We're using "lazy_author"
          # here since "author" immediately loads the data on the first call.
          @pipeline.commit.try(:lazy_author)
        end

        def preload_pipeline_warnings
          # This preloads the number of warnings for every pipeline, ensuring
          # that Ci::Pipeline#has_warnings? doesn't execute any additional
          # queries.
          @pipeline.number_of_warnings
        end

        def preload_stages_warnings
          # This preloads the number of warnings for every stage, ensuring
          # that Ci::Stage#has_warnings? doesn't execute any additional
          # queries.
          @pipeline.stages.each { |stage| stage.number_of_warnings }
        end
      end
    end
  end
end
