# frozen_string_literal: true

module ErrorTracking
  class ProjectEntity < Grape::Entity
    expose(*Gitlab::ErrorTracking::Project::ACCESSORS)
  end
end
