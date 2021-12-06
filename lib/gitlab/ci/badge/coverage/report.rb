# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    module Coverage
      ##
      # Test coverage report badge
      #
      class Report < Badge::Base
        attr_reader :project, :ref, :job, :customization

        def initialize(project, ref, opts: { job: nil })
          @project = project
          @ref = ref
          @job = opts[:job]
          @customization = {
            key_width: opts[:key_width].to_i,
            key_text: opts[:key_text],
            min_good: opts[:min_good].to_i,
            min_acceptable: opts[:min_acceptable].to_i,
            min_medium: opts[:min_medium].to_i
          }
        end

        def entity
          'coverage'
        end

        def status
          @coverage ||= raw_coverage
          return unless @coverage

          @coverage.round(2)
        end

        def metadata
          @metadata ||= Coverage::Metadata.new(self)
        end

        def template
          @template ||= Coverage::Template.new(self)
        end

        private

        def successful_pipeline
          @successful_pipeline ||= @project.ci_pipelines.latest_successful_for_ref(@ref)
        end

        def failed_pipeline
          @failed_pipeline ||= @project.ci_pipelines.latest_failed_for_ref(@ref)
        end

        def running_pipeline
          @running_pipeline ||= @project.ci_pipelines.latest_running_for_ref(@ref)
        end

        def raw_coverage
          latest =
            if @job.present?
              builds = ::Ci::Build
                .in_pipelines([successful_pipeline, running_pipeline, failed_pipeline])
                .latest
                .success
                .for_ref(@ref)
                .by_name(@job)

              builds.max_by(&:created_at)
            else
              successful_pipeline
            end

          latest&.coverage
        end
      end
    end
  end
end
