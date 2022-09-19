# frozen_string_literal: true

module Ci
  module Lockable
    extend ActiveSupport::Concern

    included do
      # `locked` will be populated from the source of truth on Ci::Pipeline
      # in order to clean up expired job artifacts in a performant way.
      # The values should be the same as `Ci::Pipeline.lockeds` with the
      # additional value of `unknown` to indicate rows that have not
      # yet been populated from the parent Ci::Pipeline
      enum locked: {
        unlocked: 0,
        artifacts_locked: 1,
        unknown: 2
      }, _prefix: :artifact
    end
  end
end
