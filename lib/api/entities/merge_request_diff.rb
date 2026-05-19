# frozen_string_literal: true

module API
  module Entities
    class MergeRequestDiff < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :head_commit_sha, documentation: { type: 'String', example: '1234abcd' }
      expose :base_commit_sha, documentation: { type: 'String', example: '1234abcd' }
      expose :start_commit_sha, documentation: { type: 'String', example: '1234abcd' }
      expose :created_at, documentation: { type: 'DateTime', example: '2022-01-31T15:10:45.080Z' }
      expose :merge_request_id, documentation: { type: 'Integer', example: 1 }
      expose :state, documentation: { type: 'String', example: 'collected' }
      expose :real_size, documentation: { type: 'String', example: '1' }
      expose :patch_id_sha, documentation: { type: 'String', example: '1234abcd' }
    end
  end
end
