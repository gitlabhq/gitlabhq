# frozen_string_literal: true

module API
  module Entities
    class RemoteMirror < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 101486 }
      expose :enabled, documentation: { type: 'Boolean', example: true }
      expose :safe_url, as: :url, documentation: { type: 'String', example: 'https://*****:*****@example.com/gitlab/example.git' }
      expose :update_status, documentation: { type: 'String', example: 'finished' }
      expose :last_update_at, documentation: { type: 'DateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_update_started_at, documentation: { type: 'DateTime', example: '2020-01-06T17:32:02.823Z' }
      expose :last_successful_update_at, documentation: { type: 'DateTime', example: '2020-01-06T17:31:55.864Z' }
      expose :last_error, documentation: { type: 'Integer', example: 'The remote mirror URL is invalid.' }
      expose :only_protected_branches, documentation: { type: 'Boolean' }
      expose :keep_divergent_refs, documentation: { type: 'Boolean' }
      expose :auth_method, documentation: { type: 'String', example: 'password' }
      expose :ssh_known_hosts_fingerprints, as: :host_keys, using: MirrorHostKey, documentation: { is_array: true }
    end
  end
end

API::Entities::RemoteMirror.prepend_mod
