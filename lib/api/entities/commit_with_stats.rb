# frozen_string_literal: true

module API
  module Entities
    class CommitWithStats < Commit
      expose :stats, using: ::API::Entities::CommitStats, documentation: { type: '::API::Entities::CommitStats' }
    end
  end
end
