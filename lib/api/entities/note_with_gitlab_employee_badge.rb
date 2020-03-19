# frozen_string_literal: true

module API
  module Entities
    class NoteWithGitlabEmployeeBadge < Note
      expose :author, using: Entities::UserWithGitlabEmployeeBadge
      expose :resolved_by, using: Entities::UserWithGitlabEmployeeBadge, if: ->(note, options) { note.resolvable? }
    end
  end
end
