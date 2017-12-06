module Gitlab
  module Ci
    module Stage
      class Seed
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

              if attributes.fetch(:stage_id).nil?
                invalid_builds_counter.increment(node: hostname)
              end
            end

            pipeline.builds.create!(builds_attributes).each do |build|
              yield build if block_given?
            end
          end
        end

        private

        def protected_ref?
          @protected_ref ||= project.protected_for?(pipeline.ref)
        end

        def invalid_builds_counter
          @counter ||= Gitlab::Metrics.counter(:invalid_builds_counter,
                                               'Builds without stage assigned counter')
        end

        def hostname
          @hostname ||= Socket.gethostname
        end
      end
    end
  end
end
