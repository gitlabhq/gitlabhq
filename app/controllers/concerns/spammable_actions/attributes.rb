# frozen_string_literal: true

module SpammableActions
  module Attributes
    extend ActiveSupport::Concern

    private

    def spammable
      raise NotImplementedError, "#{self.class} does not implement #{__method__}"
    end
  end
end
