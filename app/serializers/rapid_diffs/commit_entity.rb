# frozen_string_literal: true

module RapidDiffs
  class CommitEntity < ::CommitEntity
    expose :diff_refs, using: ::RapidDiffs::DiffRefsEntity
  end
end
