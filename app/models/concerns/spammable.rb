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
      user_agent_detail.submittable? && akismet_enabled?
    else
      false
    end
  end

  def submit_spam
    return unless akismet_enabled? && can_be_submitted?
    spam!(user_agent_detail, spammable_text, owner)
  end

  def spam_detected?(env)
    @spam = is_spam?(env, owner, spammable_text)
  end

  def spam?
    @spam
  end

  def submitted?
    if user_agent_detail
      user_agent_detail.submitted
    else
      false
    end
  end

  def check_for_spam
    self.errors.add(:base, "Your #{self.class.name.underscore} has been recognized as spam and has been discarded.") if spam?
  end

  def owner_id
    if self.respond_to?(:author_id)
      self.author_id
    elsif self.respond_to?(:creator_id)
      self.creator_id
    end
  end

  def to_ability_name
    self.class.to_s.underscore
  end

  # Override this method if an additional check is needed before calling Akismet
  def check_for_spam?
    akismet_enabled?
  end

  def spam_title
    raise NotImplementedError
  end

  def spam_description
    raise NotImplementedError
  end

  private

  def spammable_text
    result = []
    self.class.spammable_attrs.each do |entry|
      result << self.send(entry)
    end
    result.reject(&:blank?).join("\n")
  end

  def owner
    User.find(owner_id)
  end
end
