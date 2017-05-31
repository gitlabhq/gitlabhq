module Gitlab
  module Ci
    module Stage
      class Seeds
        Seed = Struct.new(:stage, :jobs)

        def initialize
          @stages = []
        end

        def has_stages?
          @stages.any?
        end

        def stages
          @stages.map(&:stage)
        end

        def jobs
          @stages.map(&:jobs).flatten
        end

        def append_stage(stage, jobs)
          @stages << Seed.new({ name: stage }, jobs)
        end

        def pipeline=(pipeline)
          trigger_request = pipeline.trigger_requests.first

          stages.each do |attributes|
            attributes.merge!(
              pipeline: pipeline,
              project: pipeline.project,
            )
          end

          jobs.each do |attributes|
            attributes.merge!(
              pipeline: pipeline,
              project: pipeline.project,
              ref: pipeline.ref,
              tag: pipeline.tag,
              trigger_request: trigger_request
            )
          end
        end

        def user=(current_user)
          jobs.each do |attributes|
            attributes.merge!(user: current_user)
          end
        end

        def to_attributes
          @stages.map do |seed|
            seed.stage.merge(builds_attributes: seed.jobs)
          end
        end
      end
    end
  end
end
