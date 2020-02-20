# frozen_string_literal: true

module API
  module Entities
    class BlameRange < Grape::Entity
      expose :commit, using: BlameRangeCommit
      expose :lines
    end
  end
end
