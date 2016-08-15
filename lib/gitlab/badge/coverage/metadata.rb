module Gitlab
  module Badge
    module Coverage
      ##
      # Class that describes coverage badge metadata
      #
      class Metadata < Badge::Metadata
        def initialize(badge)
          @project = badge.project
          @ref = badge.ref
          @job = badge.job
        end

        def title
          'coverage report'
        end

        def image_url
          coverage_namespace_project_badges_url(@project.namespace,
                                                @project, @ref,
                                                format: :svg)
        end

        def link_url
          namespace_project_commits_url(@project.namespace, @project, id: @ref)
        end
      end
    end
  end
end
