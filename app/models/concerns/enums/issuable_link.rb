# frozen_string_literal: true

module Enums
  module IssuableLink
    TYPE_RELATES_TO = 'relates_to'
    TYPE_BLOCKS = 'blocks'

    def self.link_types
      { TYPE_RELATES_TO => 0, TYPE_BLOCKS => 1 }
    end
  end
end
