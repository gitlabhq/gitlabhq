module Gitlab
  module Allowable
    def can?(user, action, subject = :global)
      Ability.allowed?(user, action, subject)
    end
  end
end
