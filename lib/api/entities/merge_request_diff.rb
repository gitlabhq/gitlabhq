# frozen_string_literal: true

module API
  module Entities
    class MergeRequestDiff < Grape::Entity
      expose :id, :head_commit_sha, :base_commit_sha, :start_commit_sha,
        :created_at, :merge_request_id, :state, :real_size, :patch_id_sha
    end
  end
end
