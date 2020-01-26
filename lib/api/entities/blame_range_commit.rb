# frozen_string_literal: true

module API
  module Entities
    class BlameRangeCommit < Grape::Entity
      expose :id
      expose :parent_ids
      expose :message
      expose :authored_date, :author_name, :author_email
      expose :committed_date, :committer_name, :committer_email
    end
  end
end
