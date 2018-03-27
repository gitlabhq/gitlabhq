module Gitlab
  module Badge
    module Coverage
      ##
      # Test coverage report badge
      #
      class Report < Badge::Base
        attr_reader :project, :ref, :job

        def initialize(project, ref, job = nil)
          @project = project
          @ref = ref
          @job = job

          @pipeline = @project.pipelines.latest_successful_for(@ref)
        end

        def entity
          'coverage'
        end

        def status
          @coverage ||= raw_coverage
          return unless @coverage

          @coverage.to_f.round(2)
        end

        def metadata
          @metadata ||= Coverage::Metadata.new(self)
        end

        def template
          @template ||= Coverage::Template.new(self)
        end

        private

        def raw_coverage
          return unless @pipeline

          if @job.blank?
            @pipeline.coverage
          else
            @pipeline.builds
              .find_by(name: @job)
              .try(:coverage)
          end
        end
      end
    end
  end
end
