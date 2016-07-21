# CSP headers have to have single quotes, so failures relating to quotes
# inside Ruby string arrays are irrelevant.
# rubocop:disable Lint/PercentStringArray
require 'gitlab/current_settings'
include Gitlab::CurrentSettings

CSP_REPORT_URI = ''

# Content Security Policy Headers
# For more information on CSP see:
# - https://gitlab.com/gitlab-org/gitlab-ce/issues/18231
# - https://developer.mozilla.org/en-US/docs/Web/Security/CSP/CSP_policy_directives
SecureHeaders::Configuration.default do |config|
  # Mark all cookies as "Secure", "HttpOnly", and "SameSite=Strict".
  config.cookies = {
    secure: true,
    httponly: true,
    samesite: {
      strict: true 
    }
  }
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"
  config.csp = {
    # "Meta" values.
    report_only: true,
    preserve_schemes: true,

    # "Directive" values.
    # Default source allows nothing, more permissive values are set per-policy.
    default_src: %w('none'),
    # (Deprecated) Don't allow iframes.
    frame_src: %w('none'),
    # Only allow XMLHTTPRequests from the GitLab instance itself.
    connect_src: %w('self'),
    # Only load local fonts.
    font_src: %w('self'),
    # Load local images, any external image available over HTTPS.
    img_src: %w(* 'self' data:),
    # Audio and video can't be played on GitLab currently, so it's disabled.
    media_src: %w('none'),
    # Don't allow <object>, <embed>, or <applet> elements.
    object_src: %w('none'),
    # Allow local scripts and inline scripts.
    script_src: %w('unsafe-inline' 'unsafe-eval' 'self'),
    # Allow local stylesheets and inline styles.
    style_src: %w('unsafe-inline' 'self'),
    # The URIs that a user agent may use as the document base URL.
    base_uri: %w('self'),
    # Only allow local iframes and service workers
    child_src: %w('self'),
    # Only submit form information to the GitLab instance.
    form_action: %w('self'),
    # Disallow any parents from embedding a page in an iframe.
    frame_ancestors: %w('none'),
    # Don't allow any plugins (Flash, Shockwave, etc.)
    plugin_types: %w(),
    # Blocks all mixed (HTTP) content.
    block_all_mixed_content: true,
    # Upgrades insecure requests to HTTPS when possible.
    upgrade_insecure_requests: true
  }

  config.csp[:report_uri] = %W(#{CSP_REPORT_URI})

  # Allow Bootstrap Linter in development mode.
  if Rails.env.development?
    config.csp[:script_src] << "maxcdn.bootstrapcdn.com"
  end

  # reCAPTCHA
  if current_application_settings.recaptcha_enabled
    config.csp[:script_src] << "https://www.google.com/recaptcha/"
    config.csp[:script_src] << "https://www.gstatic.com/recaptcha/"
    config.csp[:frame_src] << "https://www.google.com/recaptcha/"
    config.x_frame_options = "SAMEORIGIN"
  end

  # Gravatar
  if current_application_settings.gravatar_enabled?
    config.csp[:img_src] << "www.gravatar.com"
    config.csp[:img_src] << "secure.gravatar.com"
    config.csp[:img_src] << Gitlab.config.gravatar.host
  end

  # Piwik
  if Gitlab.config.extra.has_key?('piwik_url') && Gitlab.config.extra.has_key?('piwik_site_id')
    config.csp[:script_src] << Gitlab.config.extra.piwik_url
    config.csp[:img_src] << Gitlab.config.extra.piwik_url
  end

  # Google Analytics
  if Gitlab.config.extra.has_key?('google_analytics_id')
    config.csp[:script_src] << "https://www.google-analytics.com"
  end
end
