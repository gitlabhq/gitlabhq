# frozen_string_literal: true

module API
  module Entities
    module ErrorTracking
      class ProjectSetting < Grape::Entity
        expose :project_name
        expose :sentry_external_url
        expose :api_url
      end
    end
  end
end
