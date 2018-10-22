# frozen_string_literal: true

module Gitlab
  module Allowable
    def can?(*args)
      Ability.allowed?(*args)
    end
  end
end
