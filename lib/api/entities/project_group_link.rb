# frozen_string_literal: true

module API
  module Entities
    class ProjectGroupLink < Grape::Entity
      expose :id, :project_id, :group_id, :group_access, :expires_at
    end
  end
end
