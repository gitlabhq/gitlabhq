module Gitlab
  module Badge
    module Build
      ##
      # Build status badge
      #
      class Status < Badge::Base
        attr_reader :project, :ref

        def initialize(project, ref)
          @project = project
          @ref = ref

          @sha = @project.commit(@ref).try(:sha)
        end

        def entity
          'build'
        end

        def status
          @project.pipelines
            .where(sha: @sha, ref: @ref)
            .status || 'unknown'
        end

        def metadata
          @metadata ||= Build::Metadata.new(self)
        end

        def template
          @template ||= Build::Template.new(self)
        end
      end
    end
  end
end
