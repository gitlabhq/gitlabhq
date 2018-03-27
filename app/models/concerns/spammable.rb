module Spammable
  extend ActiveSupport::Concern

  module ClassMethods
    def attr_spammable(attr, options = {})
      spammable_attrs << [attr.to_s, options]
    end
  end

  included do
    has_one :user_agent_detail, as: :subject, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    attr_accessor :spam
    attr_accessor :spam_log
    alias_method :spam?, :spam

    after_validation :check_for_spam, on: [:create, :update]

    cattr_accessor :spammable_attrs, instance_accessor: false do
      []
    end

    delegate :ip_address, :user_agent, to: :user_agent_detail, allow_nil: true
  end

  def submittable_as_spam_by?(current_user)
    current_user && current_user.admin? && submittable_as_spam?
  end

  def submittable_as_spam?
    if user_agent_detail
      user_agent_detail.submittable? && Gitlab::CurrentSettings.current_application_settings.akismet_enabled
    else
      false
    end
  end

  def check_for_spam
    error_msg = if Gitlab::Recaptcha.enabled?
                  "Your #{spammable_entity_type} has been recognized as spam. "\
                  "Please, change the content or solve the reCAPTCHA to proceed."
                else
                  "Your #{spammable_entity_type} has been recognized as spam and has been discarded."
                end

    self.errors.add(:base, error_msg) if spam?
  end

  def spammable_entity_type
    self.class.name.underscore
  end

  def spam_title
    attr = self.class.spammable_attrs.find do |_, options|
      options.fetch(:spam_title, false)
    end

    public_send(attr.first) if attr && respond_to?(attr.first.to_sym) # rubocop:disable GitlabSecurity/PublicSend
  end

  def spam_description
    attr = self.class.spammable_attrs.find do |_, options|
      options.fetch(:spam_description, false)
    end

    public_send(attr.first) if attr && respond_to?(attr.first.to_sym) # rubocop:disable GitlabSecurity/PublicSend
  end

  def spammable_text
    result = self.class.spammable_attrs.map do |attr|
      public_send(attr.first) # rubocop:disable GitlabSecurity/PublicSend
    end

    result.reject(&:blank?).join("\n")
  end

  # Override in Spammable if further checks are necessary
  def check_for_spam?
    true
  end
end
