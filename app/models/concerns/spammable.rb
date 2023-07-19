# frozen_string_literal: true

module Spammable
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  class_methods do
    def attr_spammable(attr, options = {})
      spammable_attrs << [attr.to_s, options]
    end
  end

  included do
    has_one :user_agent_detail, as: :subject, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    attr_writer :spam
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

  def spam
    !!@spam # rubocop:disable Gitlab/ModuleWithInstanceVariables
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
    if self.supports_recaptcha?
      self.needs_recaptcha = true
    else
      self.spam!
    end
  end

  # Override in Spammable if recaptcha is supported
  def supports_recaptcha?
    false
  end

  ##
  # Indicates if a recaptcha should be rendered before allowing this model to be saved.
  #
  def render_recaptcha?
    return false unless Gitlab::Recaptcha.enabled? && supports_recaptcha?

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
    if needs_recaptcha? && Gitlab::Recaptcha.enabled? && supports_recaptcha?
      recaptcha_error!
    elsif needs_recaptcha? || spam?
      unrecoverable_spam_error!
    end
  end

  def recaptcha_error!
    self.errors.add(:base, _("Your %{spammable_entity_type} has been recognized as spam. "\
                    "Please, change the content or solve the reCAPTCHA to proceed.") \
                    % { spammable_entity_type: spammable_entity_type })
  end

  def unrecoverable_spam_error!
    self.errors.add(:base, _("Your %{spammable_entity_type} has been recognized as spam. "\
                    "Please, change the content to proceed.") \
                    % { spammable_entity_type: spammable_entity_type })
  end

  def spammable_entity_type
    case self
    when Issue
      _('issue')
    when MergeRequest
      _('merge request')
    when Note
      _('comment')
    when Snippet
      _('snippet')
    else
      self.class.model_name.human.downcase
    end
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

  # Override in included class if further checks are necessary
  def check_for_spam?(*)
    spammable_attribute_changed?
  end

  def spammable_attribute_changed?
    (changed & self.class.spammable_attrs.to_h.keys).any?
  end

  def check_for_spam(user:, action:, extra_features: {})
    strong_memoize_with(:check_for_spam, user, action, extra_features) do
      Spam::SpamActionService.new(spammable: self, user: user, action: action, extra_features: extra_features).execute
    end
  end

  # Override in included class if you want to allow possible spam under specific circumstances
  def allow_possible_spam?(*)
    Gitlab::CurrentSettings.allow_possible_spam
  end
end
