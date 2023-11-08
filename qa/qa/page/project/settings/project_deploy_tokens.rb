# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class ProjectDeployTokens < Page::Base
          include Page::Component::DeployToken
        end
      end
    end
  end
end
