# frozen_string_literal: true

module API
  module Entities
    class CommitWithStats < Commit
      expose :stats, using: Entities::CommitStats
    end
  end
end
