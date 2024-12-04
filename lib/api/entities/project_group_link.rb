# frozen_string_literal: true

module API
  module Entities
    class ProjectGroupLink < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :project_id, documentation: { type: 'integer', example: 1 }
      expose :group_id, documentation: { type: 'integer', example: 1 }
      expose :group_access, documentation: { type: 'integer', example: 10 }
      expose :expires_at, documentation: { type: 'date', example: '2016-09-26' }
    end
  end
end

API::Entities::ProjectGroupLink.prepend_mod
