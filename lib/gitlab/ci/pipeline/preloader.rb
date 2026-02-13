# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      # Class for preloading data associated with pipelines such as commit
      # authors.
      class Preloader
        def self.preload!(pipelines)
          ##
          # This preloads all commits at once, because `Ci::Pipeline#commit` is
          # using a lazy batch loading, what results in only one batched Gitaly
          # call.
          #
          pipelines.each(&:commit)

          pipelines.each do |pipeline|
            self.new(pipeline).tap do |preloader|
              preloader.preload_commit_authors
              preloader.preload_ref_commits
              preloader.preload_pipeline_warnings
              preloader.preload_stages_warnings
              preloader.preload_persisted_environments
            end
          end
        end

        def initialize(pipeline)
          @pipeline = pipeline
        end

        # This also preloads the author of every commit. We're using "lazy_author"
        # here since "author" immediately loads the data on the first call.
        def preload_commit_authors
          @pipeline.commit.try(:lazy_author)
        end

        # This preloads latest commits for given refs and therefore makes it
        # much less expensive to check if a pipeline is a latest one for
        # given branch.
        def preload_ref_commits
          @pipeline.lazy_ref_commit
        end

        def preload_pipeline_warnings
          # This preloads the number of warnings for every pipeline, ensuring
          # that Ci::Pipeline#has_warnings? doesn't execute any additional
          # queries.
          @pipeline.number_of_warnings
        end

        # This preloads the number of warnings for every stage, ensuring
        # that Ci::Stage#has_warnings? doesn't execute any additional
        # queries.
        def preload_stages_warnings
          @pipeline.stages.each { |stage| stage.number_of_warnings }
        end

        # This batch loads the associated environments of multiple actions (builds)
        # that can't use `preload` due to the indirect relationship.
        def preload_persisted_environments
          @pipeline.scheduled_actions.each { |action| action.persisted_environment }
          @pipeline.manual_actions.each { |action| action.persisted_environment }
        end
      end
    end
  end
end
