# frozen_string_literal: true

module API
  module Entities
    class CommitStats < Grape::Entity
      expose :additions, :deletions, :total
    end
  end
end
