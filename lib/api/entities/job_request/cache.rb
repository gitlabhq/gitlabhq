# frozen_string_literal: true

module API
  module Entities
    module JobRequest
      class Cache < Grape::Entity
        expose :key, :untracked, :paths, :policy
      end
    end
  end
end
