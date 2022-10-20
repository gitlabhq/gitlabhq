# frozen_string_literal: true

module API
  module Entities
    class PullMirror < Grape::Entity
      expose :id
      expose :status, as: :update_status
      expose :url do |import_state|
        import_state.project.safe_import_url
      end
      expose :last_error
      expose :last_update_at
      expose :last_update_started_at
      expose :last_successful_update_at
    end
  end
end
