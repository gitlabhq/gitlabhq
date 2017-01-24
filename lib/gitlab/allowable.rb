module Gitlab
  module Allowable
    def can?(user, action, subject)
      Ability.allowed?(user, action, subject)
    end
  end
end
