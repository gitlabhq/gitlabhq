# frozen_string_literal: true

module API
  module Entities
    class ProjectScopeLink < Grape::Entity
      expose :source_project_id, documentation: { type: 'Integer' }
      expose :target_project_id, documentation: { type: 'Integer' }
    end
  end
end
