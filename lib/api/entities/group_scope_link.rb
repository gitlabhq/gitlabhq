# frozen_string_literal: true

module API
  module Entities
    class GroupScopeLink < Grape::Entity
      expose :source_project_id, documentation: { type: 'Integer' }
      expose :target_group_id, documentation: { type: 'Integer' }
    end
  end
end
