module Gitlab
  module Badge
    module Pipeline
      ##
      # Class that describes pipeline badge metadata
      #
      class Metadata < Badge::Metadata
        def initialize(badge)
          @project = badge.project
          @ref = badge.ref
        end

        def title
          'pipeline status'
        end

        def image_url
          pipeline_project_badges_url(@project, @ref, format: :svg)
        end

        def link_url
          project_commits_url(@project, id: @ref)
        end
      end
    end
  end
end
