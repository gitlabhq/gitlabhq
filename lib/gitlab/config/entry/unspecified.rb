# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # This class represents an unspecified entry.
      #
      # It decorates original entry adding method that indicates it is
      # unspecified.
      #
      class Unspecified < SimpleDelegator
        def specified?
          false
        end
      end
    end
  end
end
