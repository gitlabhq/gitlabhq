# frozen_string_literal: true

module Gitlab::Ci
  module Badge
    module Release
      class Metadata < Badge::Metadata
        def initialize(badge)
          @project = badge.project
        end

        def title
          'Latest Release'
        end

        def image_url
          release_project_badges_url(@project, format: :svg)
        end

        def link_url
          project_releases_url(@project)
        end
      end
    end
  end
end
