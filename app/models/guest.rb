class Guest
  class << self
    def can?(action, subject = :global)
      Ability.allowed?(nil, action, subject)
    end
  end
end
