# frozen_string_literal: true

module API
  module Entities
    class ProjectGroupLink < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :project_id, documentation: { type: 'Integer', example: 1 }
      expose :group_id, documentation: { type: 'Integer', example: 1 }
      expose :group_access, documentation: { type: 'Integer', example: 10 }
      expose :expires_at, documentation: { type: 'Date', example: '2016-09-26' }
    end
  end
end

API::Entities::ProjectGroupLink.prepend_mod
