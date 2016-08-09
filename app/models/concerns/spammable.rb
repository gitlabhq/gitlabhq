module Spammable
  extend ActiveSupport::Concern

  included do
    attr_accessor :spam
    after_validation :check_for_spam, on: :create
  end

  def spam?
    @spam
  end

  def check_for_spam
    self.errors.add(:base, "Your #{self.class.name.underscore} has been recognized as spam and has been discarded.") if spam?
  end
end
