# frozen_string_literal: true

module Gitlab
  module Allowable
    def can?(...)
      Ability.allowed?(...)
    end

    def can_any?(user, abilities, subject = :global, **opts)
      abilities.any? do |ability|
        can?(user, ability, subject, **opts)
      end
    end
  end
end
