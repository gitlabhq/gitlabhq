module Gitlab
  module Ci
    module Stage
      class Seed
        attr_reader :name, :builds

        def initialize(name:, builds:)
          @name = name
          @builds = builds
        end

        def pipeline=(pipeline)
          trigger_request = pipeline.trigger_requests.first

          @builds.each do |attributes|
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
          @builds.each do |attributes|
            attributes.merge!(user: current_user)
          end
        end

        def to_attributes
          { name: @name, builds_attributes: @builds }
        end
      end
    end
  end
end
