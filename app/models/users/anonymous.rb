# frozen_string_literal: true

module Users
  class Anonymous
    class << self
      def can?(action, subject = :global)
        Ability.allowed?(nil, action, subject)
      end
    end
  end
end
