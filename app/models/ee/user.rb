module EE
  # User EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `User` model
  module User
    extend ActiveSupport::Concern

    def access_level
      if admin?
        :admin
      elsif auditor?
        :auditor
      else
        :regular
      end
    end

    def access_level=(new_level)
      new_level = new_level.to_sym
      return unless [:admin, :auditor, :regular].include?(new_level)

      self.admin = self.auditor = false

      self.admin = true if new_level == :admin
      self.auditor = true if new_level == :auditor
    end
  end
end
