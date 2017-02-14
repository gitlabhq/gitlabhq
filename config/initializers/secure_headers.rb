# CSP headers have to have single quotes, so failures relating to quotes
# inside Ruby string arrays are irrelevant.
# rubocop:disable Lint/PercentStringArray
require 'gitlab/current_settings'
include Gitlab::CurrentSettings

# If Sentry is enabled and the Rails app is running in production mode,
# this will construct the Report URI for Sentry.
if Rails.env.production? && current_application_settings.sentry_enabled
  uri = URI.parse(current_application_settings.sentry_dsn)
  CSP_REPORT_URI = "#{uri.scheme}://#{uri.host}/api#{uri.path}/csp-report/?sentry_key=#{uri.user}"
else
  CSP_REPORT_URI = ''
end

# Get the GitLab URI without the scheme so it can have wss:// prepended.
GITLAB_WS_URI = Gitlab.config.gitlab['url'].sub(%r{^https?:(//|\\\\)(www\.)?}i, '')

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
  config.csp = {
    # "Meta" values.
    preserve_schemes: true,

    # "Directive" values.
    # Default source allows nothing, more permissive values are set per-policy.
    default_src: %w('none'),
    # (Deprecated) Don't allow iframes.
    frame_src: %w('self'),
    # Only allow XMLHTTPRequests from the GitLab instance itself.
    # Only allow WebSockets connections from the GitLab instance itself.
    connect_src: %W('self' "wss://#{GITLAB_WS_URI}"),
    # Only load local fonts.
    font_src: %w('self'),
    # Load local images, any external image available over HTTP.
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
    frame_ancestors: %w('self'),
    # Don't allow any plugins (Flash, Shockwave, etc.)
    plugin_types: %w(),
    # Don't block mixed content.
    block_all_mixed_content: false,
    # Upgrades insecure requests to HTTPS when possible.
    upgrade_insecure_requests: true
  }

  # Reports are sent to Sentry if it's enabled.
  if current_application_settings.sentry_enabled
    config.csp[:report_uri] = %W(#{CSP_REPORT_URI})
  end

  if Rails.env.development?
    # Allow Bootstrap Linter in development mode.
    config.csp[:script_src] << "maxcdn.bootstrapcdn.com"
    # Disable upgrade_insecure_requests so we don't need an SSL cert in development.
    config.csp[:upgrade_insecure_requests] = false
    
    # Determine current host, connect through port 3808 for Webpack.
    uri = URI.parse(Gitlab.config.gitlab['url'])
    WEBPACK_CONNECT_URI = "#{uri.scheme}://#{uri.host}:3808"
    WEBPACK_CONNECT_WS_URI = "ws://#{uri.host}:3808"

    # Allow Webpack's dev server
    config.csp[:connect_src] << "#{WEBPACK_CONNECT_URI}"
    config.csp[:connect_src] << "#{WEBPACK_CONNECT_WS_URI}"
  end

  # reCAPTCHA
  if current_application_settings.recaptcha_enabled
    config.csp[:script_src] << "https://www.google.com/recaptcha/"
    config.csp[:script_src] << "https://www.gstatic.com/recaptcha/"
    config.csp[:frame_src] << "https://www.google.com/recaptcha/"
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
