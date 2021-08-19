# frozen_string_literal: true

module Spammable
  extend ActiveSupport::Concern

  class_methods do
    def attr_spammable(attr, options = {})
      spammable_attrs << [attr.to_s, options]
    end
  end

  included do
    has_one :user_agent_detail, as: :subject, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    attr_accessor :spam
    attr_accessor :needs_recaptcha
    attr_accessor :spam_log

    alias_method :spam?, :spam
    alias_method :needs_recaptcha?, :needs_recaptcha

    # if spam errors are added before validation, they will be wiped
    after_validation :invalidate_if_spam, on: [:create, :update]

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

  def needs_recaptcha!
    self.needs_recaptcha = true
  end

  ##
  # Indicates if a recaptcha should be rendered before allowing this model to be saved.
  #
  def render_recaptcha?
    return false unless Gitlab::Recaptcha.enabled?

    return false if self.errors.count > 1 # captcha should not be rendered if are still other errors

    self.needs_recaptcha?
  end

  def spam!
    self.spam = true
  end

  def clear_spam_flags!
    self.spam = false
    self.needs_recaptcha = false
  end

  def invalidate_if_spam
    if needs_recaptcha? && Gitlab::Recaptcha.enabled?
      recaptcha_error!
    elsif needs_recaptcha? || spam?
      unrecoverable_spam_error!
    end
  end

  def recaptcha_error!
    self.errors.add(:base, "Your #{spammable_entity_type} has been recognized as spam. "\
                    "Please, change the content or solve the reCAPTCHA to proceed.")
  end

  def unrecoverable_spam_error!
    self.errors.add(:base, "Your #{spammable_entity_type} has been recognized as spam and has been discarded.")
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
  def check_for_spam?(user:)
    true
  end

  # Override in Spammable if differs
  def allow_possible_spam?
    Feature.enabled?(:allow_possible_spam, project)
  end
end
