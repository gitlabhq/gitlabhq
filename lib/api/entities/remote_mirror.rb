# frozen_string_literal: true

module API
  module Entities
    class RemoteMirror < Grape::Entity
      expose :id
      expose :enabled
      expose :safe_url, as: :url
      expose :update_status
      expose :last_update_at
      expose :last_update_started_at
      expose :last_successful_update_at
      expose :last_error
      expose :only_protected_branches
      expose :keep_divergent_refs
    end
  end
end
