# frozen_string_literal: true

module API
  module Entities
    class RemoteMirror < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 101486 }
      expose :enabled, documentation: { type: 'boolean', example: true }
      expose :safe_url, as: :url, documentation: { type: 'string', example: 'https://*****:*****@example.com/gitlab/example.git' }
      expose :update_status, documentation: { type: 'string', example: 'finished' }
      expose :last_update_at, documentation: { type: 'dateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_update_started_at, documentation: { type: 'dateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_successful_update_at, documentation: { type: 'dateTime', example: '2020-01-06T17:31:55.864Z' }
      expose :last_error, documentation: { type: 'integer', example: 'The remote mirror URL is invalid.' }
      expose :only_protected_branches, documentation: { type: 'boolean' }
      expose :keep_divergent_refs, documentation: { type: 'boolean' }
      expose :auth_method, documentation: { type: 'string', example: 'password' }
    end
  end
end

API::Entities::RemoteMirror.prepend_mod
