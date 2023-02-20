# frozen_string_literal: true

module Gitlab
  module Allowable
    def can?(...)
      Ability.allowed?(...)
    end
  end
end
