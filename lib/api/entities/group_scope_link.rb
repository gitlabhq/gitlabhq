# frozen_string_literal: true

module API
  module Entities
    class GroupScopeLink < Grape::Entity
      expose :source_project_id, documentation: { type: 'integer' }
      expose :target_group_id, documentation: { type: 'integer' }
    end
  end
end
