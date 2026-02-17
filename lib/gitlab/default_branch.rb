# frozen_string_literal: true

module Gitlab
  module DefaultBranch
    def self.value(object: nil) # rubocop:disable Lint/UnusedMethodArgument -- Keep for backward compatibility
      'main'
    end
  end
end
