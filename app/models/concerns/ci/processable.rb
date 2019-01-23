# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that need to be implemented by CI/CD
  # entities that are supposed to go through pipeline processing
  # services.
  #
  #
  module Processable
    def schedulable?
      raise NotImplementedError
    end

    def action?
      raise NotImplementedError
    end

    def when
      raise NotImplementedError
    end

    def expanded_environment_name
      raise NotImplementedError
    end
  end
end
