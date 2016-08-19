module Gitlab
  module Badge
    module Build
      ##
      # Class that describes build badge metadata
      #
      class Metadata < Badge::Metadata
        def initialize(badge)
          @project = badge.project
          @ref = badge.ref
        end

        def title
          'build status'
        end

        def image_url
          build_namespace_project_badges_url(@project.namespace,
                                             @project, @ref, format: :svg)
        end

        def link_url
          namespace_project_commits_url(@project.namespace, @project, id: @ref)
        end
      end
    end
  end
end
