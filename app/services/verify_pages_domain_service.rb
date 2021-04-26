# frozen_string_literal: true

require 'resolv'

class VerifyPagesDomainService < BaseService
  # The maximum number of seconds to be spent on each DNS lookup
  RESOLVER_TIMEOUT_SECONDS = 15

  # How long verification lasts for
  VERIFICATION_PERIOD = 7.days
  REMOVAL_DELAY = 1.week.freeze

  attr_reader :domain

  def initialize(domain)
    @domain = domain
  end

  def execute
    return error("No verification code set for #{domain.domain}") unless domain.verification_code.present?

    if !verification_enabled? || dns_record_present?
      verify_domain!
    elsif expired?
      disable_domain!
    else
      unverify_domain!
    end
  end

  private

  def verify_domain!
    was_disabled = !domain.enabled?
    was_unverified = domain.unverified?

    # Prevent any pre-existing grace period from being truncated
    reverify = [domain.enabled_until, VERIFICATION_PERIOD.from_now].compact.max

    domain.assign_attributes(verified_at: Time.current, enabled_until: reverify, remove_at: nil)
    domain.save!(validate: false)

    if was_disabled
      notify(:enabled)
    elsif was_unverified
      notify(:verification_succeeded)
    end

    success
  end

  def unverify_domain!
    was_verified = domain.verified?

    domain.assign_attributes(verified_at: nil)
    domain.remove_at ||= REMOVAL_DELAY.from_now unless domain.enabled?
    domain.save!(validate: false)

    notify(:verification_failed) if was_verified

    error("Couldn't verify #{domain.domain}")
  end

  def disable_domain!
    domain.assign_attributes(verified_at: nil, enabled_until: nil)
    domain.remove_at ||= REMOVAL_DELAY.from_now
    domain.save!(validate: false)

    notify(:disabled)

    error("Couldn't verify #{domain.domain}. It is now disabled.")
  end

  # A domain is only expired until `disable!` has been called
  def expired?
    domain.enabled_until && domain.enabled_until < Time.current
  end

  def dns_record_present?
    Resolv::DNS.open do |resolver|
      resolver.timeouts = RESOLVER_TIMEOUT_SECONDS

      check(domain.domain, resolver) || check(domain.verification_domain, resolver)
    end
  end

  def check(domain_name, resolver)
    records = parse(txt_records(domain_name, resolver))

    records.any? do |record|
      record == domain.keyed_verification_code || record == domain.verification_code
    end
  rescue StandardError => err
    log_error("Failed to check TXT records on #{domain_name} for #{domain.domain}: #{err}")
    false
  end

  def txt_records(domain_name, resolver)
    resolver.getresources(domain_name, Resolv::DNS::Resource::IN::TXT)
  end

  def parse(records)
    records.flat_map(&:strings).flat_map(&:split)
  end

  def verification_enabled?
    Gitlab::CurrentSettings.pages_domain_verification_enabled?
  end

  def notify(type)
    return unless verification_enabled?

    Gitlab::AppLogger.info("Pages domain '#{domain.domain}' changed state to '#{type}'")
    notification_service.public_send("pages_domain_#{type}", domain) # rubocop:disable GitlabSecurity/PublicSend
  end
end
