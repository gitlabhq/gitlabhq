# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Cache < Grape::Entity
          expose :key, :untracked, :paths, :policy, :when, :fallback_keys
        end
      end
    end
  end
end
