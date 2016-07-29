module Spammable
  extend ActiveSupport::Concern
  include Gitlab::AkismetHelper

  module ClassMethods
    def attr_spammable(*attrs)
      attrs.each do |attr|
        spammable_attrs << attr.to_s
      end
    end
  end

  included do
    has_one :user_agent_detail, as: :subject, dependent: :destroy
    attr_accessor :spam
    after_validation :check_for_spam, on: :create

    cattr_accessor :spammable_attrs, instance_accessor: false do
      []
    end
  end

  def can_be_submitted?
    if user_agent_detail
      user_agent_detail.submittable?
    else
      false
    end
  end

  def submit_ham
    return unless akismet_enabled? && can_be_submitted?
    ham!(user_agent_detail, spammable_text, creator)
  end

  def submit_spam
    return unless akismet_enabled? && can_be_submitted?
    spam!(user_agent_detail, spammable_text, creator)
  end

  def spam?(env, user)
    is_spam?(env, user, spammable_text)
  end

  def spam_detected?
    @spam
  end

  def check_for_spam
    self.errors.add(:base, "Your #{self.class.name.underscore} has been recognized as spam and has been discarded.") if spam_detected?
  end

  private

  def spammable_text
    result = []
    self.class.spammable_attrs.each do |entry|
      result << self.send(entry)
    end
    result.reject(&:blank?).join("\n")
  end

  def creator
    if self.author_id
      User.find(self.author_id)
    elsif self.creator_id
      User.find(self.creator_id)
    end
  end
end
