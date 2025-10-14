# frozen_string_literal: true

module Gitlab
  module Ci
    module Badge
      module Custom
        ##
        # Class that describes pipeline badge metadata
        #
        class Metadata < Badge::Metadata
          def initialize(badge)
            @project = badge.project
          end

          def title
            'custom'
          end

          def image_url
            custom_project_badges_url(@project, format: :svg)
          end

          def link_url
            project_url(@project)
          end
        end
      end
    end
  end
end
