module Gitlab
  module Ci
    module Stage
      class Seed
        include ::Gitlab::Utils::StrongMemoize

        attr_reader :pipeline

        delegate :project, to: :pipeline
        delegate :size, to: :@jobs

        def initialize(pipeline, stage, jobs)
          @pipeline = pipeline
          @stage = { name: stage }
          @jobs = jobs.to_a.dup
        end

        def user=(current_user)
          @jobs.map! do |attributes|
            attributes.merge(user: current_user)
          end
        end

        def stage
          @stage.merge(project: project)
        end

        def builds
          trigger = pipeline.trigger_requests.first

          @jobs.map do |attributes|
            attributes.merge(project: project,
                             ref: pipeline.ref,
                             tag: pipeline.tag,
                             trigger_request: trigger,
                             protected: protected_ref?)
          end
        end

        def create!
          pipeline.stages.create!(stage).tap do |stage|
            builds_attributes = builds.map do |attributes|
              attributes.merge(stage_id: stage.id)
            end

            pipeline.builds.create!(builds_attributes).each do |build|
              yield build if block_given?
            end
          end
        end

        private

        def protected_ref?
          strong_memoize(:protected_ref) do
            project.protected_for?(pipeline.ref)
          end
        end
      end
    end
  end
end
