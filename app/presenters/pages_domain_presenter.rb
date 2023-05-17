# frozen_string_literal: true

class PagesDomainPresenter < Gitlab::View::Presenter::Delegated
  presents ::PagesDomain, as: :pages_domain

  def needs_verification?
    Gitlab::CurrentSettings.pages_domain_verification_enabled? && unverified?
  end

  def show_auto_ssl_failed_warning?
    # validations prevents auto ssl from working, so there is no need to show that warning until
    return false if needs_verification?

    ::Gitlab::LetsEncrypt.enabled? && auto_ssl_failed
  end

  def user_defined_certificate?
    persisted? &&
      certificate.present? &&
      certificate_user_provided? &&
      errors[:certificate].blank?
  end
end
