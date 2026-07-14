# frozen_string_literal: true

module API
  module Entities
    class GroupScopeLink < Grape::Entity
      expose :source_project_id, documentation: { type: 'Integer', format: 'int64' }
      expose :target_group_id, documentation: { type: 'Integer', format: 'int64' }
    end
  end
end
