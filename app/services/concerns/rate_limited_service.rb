# frozen_string_literal: true

module RateLimitedService
  extend ActiveSupport::Concern

  RateLimitedNotSetupError = Class.new(StandardError)

  class RateLimitedError < StandardError
    def initialize(key:, rate_limiter:)
      @key = key
      @rate_limiter = rate_limiter
    end

    def headers
      # TODO: This will be fleshed out in https://gitlab.com/gitlab-org/gitlab/-/issues/342370
      {}
    end

    def log_request(request, current_user)
      rate_limiter.log_request(request, "#{key}_request_limit".to_sym, current_user)
    end

    private

    attr_reader :key, :rate_limiter
  end

  class RateLimiterScopedAndKeyed
    attr_reader :key, :opts, :rate_limiter

    def initialize(key:, opts:, rate_limiter:)
      @key = key
      @opts = opts
      @rate_limiter = rate_limiter
    end

    def rate_limit!(service)
      evaluated_scope = evaluated_scope_for(service)

      if rate_limiter.throttled?(key, **opts.merge(scope: evaluated_scope.values, users_allowlist: users_allowlist))
        raise RateLimitedError.new(key: key, rate_limiter: rate_limiter), _('This endpoint has been requested too many times. Try again later.')
      end
    end

    private

    def users_allowlist
      @users_allowlist ||= opts[:users_allowlist] ? opts[:users_allowlist].call : []
    end

    def evaluated_scope_for(service)
      opts[:scope].index_with do |var|
        service.public_send(var) # rubocop: disable GitlabSecurity/PublicSend
      end
    end
  end

  prepended do
    attr_accessor :rate_limiter_bypassed

    cattr_accessor :rate_limiter_scoped_and_keyed

    def self.rate_limit(key:, opts:, rate_limiter: ::Gitlab::ApplicationRateLimiter)
      self.rate_limiter_scoped_and_keyed = RateLimiterScopedAndKeyed.new(
        key: key,
        opts: opts,
        rate_limiter: rate_limiter
      )
    end
  end

  def execute_without_rate_limiting(*args, **kwargs)
    self.rate_limiter_bypassed = true
    execute(*args, **kwargs)
  ensure
    self.rate_limiter_bypassed = false
  end

  def execute(*args, **kwargs)
    raise RateLimitedNotSetupError if rate_limiter_scoped_and_keyed.nil?

    rate_limiter_scoped_and_keyed.rate_limit!(self) unless rate_limiter_bypassed

    super
  end
end
