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
    after_validation :spam_detected?, on: :create

    cattr_accessor :spammable_attrs, instance_accessor: false do
      []
    end
    delegate :submitted?, to: :user_agent_detail, allow_nil: true
  end

  def can_be_submitted?
    if user_agent_detail
      user_agent_detail.submittable?
    else
      false
    end
  end

  def spam?
    @spam
  end

  def spam_detected?
    self.errors.add(:base, "Your #{self.class.name.underscore} has been recognized as spam and has been discarded.") if spam?
  end

  def owner_id
    if self.respond_to?(:author_id)
      self.author_id
    elsif self.respond_to?(:creator_id)
      self.creator_id
    end
  end

  def owner
    User.find(owner_id)
  end

  def spam_title
    attr = self.class.spammable_attrs.select do |_, options|
      options.fetch(:spam_title, false)
    end

    attr = attr[0].first

    public_send(attr) if respond_to?(attr.to_sym)
  end

  def spam_description
    attr = self.class.spammable_attrs.select do |_, options|
      options.fetch(:spam_description, false)
    end

    attr = attr[0].first

    public_send(attr) if respond_to?(attr.to_sym)
  end

  def spammable_text
    result = []
    self.class.spammable_attrs.map do |attr|
      result << public_send(attr.first)
    end

    result.reject(&:blank?).join("\n")
  end

  # Override in Spammable if further checks are necessary
  def check_for_spam?
    current_application_settings.akismet_enabled
  end
end
