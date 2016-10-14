module Spammable
  extend ActiveSupport::Concern

  module ClassMethods
    def attr_spammable(attr, options = {})
      spammable_attrs << [attr.to_s, options]
    end
  end

  included do
    has_one :user_agent_detail, as: :subject, dependent: :destroy

    attr_accessor :spam

    after_validation :check_for_spam, on: :create

    cattr_accessor :spammable_attrs, instance_accessor: false do
      []
    end

    delegate :ip_address, :user_agent, to: :user_agent_detail, allow_nil: true
  end

  def submittable_as_spam?
    if user_agent_detail
      user_agent_detail.submittable? && current_application_settings.akismet_enabled
    else
      false
    end
  end

  def spam?
    @spam
  end

  def check_for_spam
    self.errors.add(:base, "Your #{self.class.name.underscore} has been recognized as spam and has been discarded.") if spam?
  end

  def spam_title
    attr = self.class.spammable_attrs.find do |_, options|
      options.fetch(:spam_title, false)
    end

    public_send(attr.first) if attr && respond_to?(attr.first.to_sym)
  end

  def spam_description
    attr = self.class.spammable_attrs.find do |_, options|
      options.fetch(:spam_description, false)
    end

    public_send(attr.first) if attr && respond_to?(attr.first.to_sym)
  end

  def spammable_text
    result = self.class.spammable_attrs.map do |attr|
      public_send(attr.first)
    end

    result.reject(&:blank?).join("\n")
  end

  # Override in Spammable if further checks are necessary
  def check_for_spam?
    true
  end
end
