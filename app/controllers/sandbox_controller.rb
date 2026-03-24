# frozen_string_literal: true

class SandboxController < ApplicationController # rubocop:disable Gitlab/NamespacedClass
  skip_before_action :authenticate_user!
  skip_before_action :enforce_terms!
  skip_before_action :check_two_factor_requirement

  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  content_security_policy(only: :mermaid) do |p|
    SandboxController.apply_mermaid_csp(p)
  end

  def mermaid
    render layout: false
  end

  def swagger
    render layout: false
  end

  class << self
    # Build a purpose-specific CSP for the Mermaid sandbox from scratch, ignoring any global CSP
    # configuration. Since Mermaid itself is third-party code and we're currently blocked on
    # upgrading it (https://gitlab.com/gitlab-org/gitlab/-/issues/554889), it may have bugs we
    # cannot easily address, and we need to contain it.
    #
    # * We clear all inherited directives and build from scratch so the policy is predictable and
    #   independent of the global CSP setting.
    #
    # * img-src and media-src default to a permissive set matching the global defaults, but are
    #   overridden to a restrictive allowlist when the asset proxy is enabled to prevent leaks.
    #
    # * script-src allows 'self' (for the webpack/Vite bundle served from the same origin) and
    #   'unsafe-eval' (required by Mermaid's rendering engine).
    #
    #   Critically, 'unsafe-inline' is NOT included -- this is what blocks inline event handlers
    #   injected via Mermaid XSS payloads (e.g. <img onerror="...">).
    #
    #   When the global CSP is enabled, the Rails middleware appends a nonce which covers cross-
    #   origin dev server scripts; in case it's disabled, we explicitly allow the Vite dev server
    #   origin in development/test, otherwise we won't load Mermaid in dev at all when CSP is off.
    #
    # * style-src allows 'unsafe-inline' because Mermaid injects <style> tags and inline style=
    #   attributes in its SVG output.
    #
    # * worker-src and connect-src are 'none' -- Mermaid doesn't use web workers or fetch/XHR in
    #   our configuration. In development/test, allow_vite_dev_server appends the Vite origin as
    #   needed. (Per spec, 'none' is ignored for a directive if there are other sources listed,
    #   thus allowing only the Vite URLs).
    #
    # * frame-src and object-src are 'none' -- the sandbox should never embed iframes or plugins.
    def apply_mermaid_csp(policy)
      policy.directives.clear

      directives = mermaid_sandbox_directives

      # Note these two calls only have an effect in dev/test.
      Gitlab::ContentSecurityPolicy::ConfigLoader.allow_vite_dev_server(directives)
      Gitlab::ContentSecurityPolicy::ConfigLoader.allow_vite_dev_server_script(directives)

      apply_directives(policy, directives)

      return unless Gitlab.config.asset_proxy.enabled && Gitlab.config.asset_proxy.csp_directives

      policy.img_src(*Gitlab.config.asset_proxy.csp_directives)
      policy.media_src(*Gitlab.config.asset_proxy.csp_directives)
    end

    private

    def mermaid_sandbox_directives
      {
        'img_src' => "'self' data: blob: http: https:",
        'media_src' => "'self' data: blob: http: https:",
        'script_src' => "'self' 'unsafe-eval'",
        'style_src' => "'self' 'unsafe-inline'",
        'base_uri' => "'self'",
        'default_src' => "'self'",
        'font_src' => "'self'",
        'worker_src' => "'none'",
        'connect_src' => "'none'",
        'frame_src' => "'none'",
        'object_src' => "'none'"
      }
    end

    def apply_directives(policy, directives)
      directives.each do |directive, value|
        next unless value.present?

        policy.public_send(directive, *value.split) # rubocop:disable GitlabSecurity/PublicSend -- no other way to set
      end
    end
  end
end
