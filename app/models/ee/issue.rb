module EE
  module Issue
    # override
    def check_for_spam?
      return true if author.support_bot?

      super
    end
  end
end
