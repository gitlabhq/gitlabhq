# frozen_string_literal: true

module RapidDiffs
  class MergeRequestDiffEntity < ::MergeRequestDiffEntity
    expose :id
    expose :head_commit_sha
  end
end
