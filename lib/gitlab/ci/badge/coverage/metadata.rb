# frozen_string_literal: true

module Gitlab::Ci
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
          coverage_project_badges_url(@project, @ref, format: :svg)
        end

        def link_url
          project_commits_url(@project, @ref)
        end
      end
    end
  end
end
