module Gitlab
  module Ci
    module Stage
      class Seed
        include ::Gitlab::Utils::StrongMemoize

        attr_reader :pipeline

        delegate :project, to: :pipeline
        delegate :size, to: :@builds

        def initialize(pipeline, stage, builds)
          @pipeline = pipeline
          @stage = stage            # stage name
          @builds = builds.to_a.dup # builds array of hashes
        end

        def user=(current_user)
          @builds.map! do |attributes|
            attributes.merge(user: current_user)
          end
        end

        def stage_attributes
          { name: @stage, project: project }
        end

        def builds_attributes
          trigger = pipeline.trigger_requests.first

          @builds.map do |attributes|
            attributes.merge(project: project,
                             ref: pipeline.ref,
                             tag: pipeline.tag,
                             trigger_request: trigger,
                             protected: protected_ref?)
          end
        end

        def create!
          pipeline.stages.build(stage_attributes).tap do |stage|
            builds_attributes.each do |build_attributes|
              stage.builds.build(build_attributes).tap do |build|
                build.pipeline = pipeline
              end
            end

            stage.save!

            stage.builds.each do |build|
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
