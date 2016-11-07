class Guest
  class << self
    def can?(action, subject)
      Ability.allowed?(nil, action, subject)
    end
  end
end
