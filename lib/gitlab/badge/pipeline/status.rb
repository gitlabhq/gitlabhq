module Gitlab
  module Badge
    module Pipeline
      ##
      # Pipeline status badge
      #
      class Status < Badge::Base
        attr_reader :project, :ref

        def initialize(project, ref)
          @project = project
          @ref = ref

          @sha = @project.commit(@ref).try(:sha)
        end

        def entity
          'pipeline'
        end

        def status
          @project.pipelines
            .where(sha: @sha)
            .latest_status(@ref) || 'unknown'
        end

        def metadata
          @metadata ||= Pipeline::Metadata.new(self)
        end

        def template
          @template ||= Pipeline::Template.new(self)
        end
      end
    end
  end
end
