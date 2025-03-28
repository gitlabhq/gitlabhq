# frozen_string_literal: true

module Gitlab
  module Security
    class DastVariables
      def self.ci_variables_documentation_link
        Gitlab::Routing.url_helpers.help_page_path('ci/variables/_index.md', anchor: 'define-a-cicd-variable-in-the-ui')
      end

      # rubocop: disable Metrics/AbcSize -- Generate dynamic translation as per
      # https://docs.gitlab.com/ee/development/i18n/externalization.html#keep-translations-dynamic
      def self.data
        {
          site: {
            DAST_ACTIVE_SCAN_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "3h",
              name: s_("DastProfiles|Active scan timeout"),
              description: s_(
                "DastProfiles|The maximum amount of time to wait for the active scan phase of the scan to complete. " \
                  "Defaults to 3h."
              )
            },
            DAST_ACTIVE_SCAN_WORKER_COUNT: {
              additional: true,
              type: "number",
              example: 3,
              name: s_("DastProfiles|Active scan worker count"),
              description: s_("DastProfiles|The number of active checks to run in parallel. Defaults to 3.")
            },
            DAST_AUTH_AFTER_LOGIN_ACTIONS: {
              additional: true,
              auth: true,
              type: "string",
              example: "click(on=id:remember-me),click(on=css:.continue)",
              name: s_("DastProfiles|After-login actions"),
              description: s_(
                "DastProfiles|A comma-separated list of actions to be run after login but before login " \
                  "verification. Currently supports `click` actions."
              )
            },
            DAST_AUTH_BEFORE_LOGIN_ACTIONS: {
              additional: true,
              auth: true,
              type: "selector",
              example: "css:.user,id:show-login-form",
              name: s_("DastProfiles|Before-login actions"),
              description: s_(
                "DastProfiles|A comma-separated list of selectors representing elements to click on " \
                  "prior to entering the DAST_AUTH_USERNAME and DAST_AUTH_PASSWORD into the login form."
              )
            },
            DAST_AUTH_CLEAR_INPUT_FIELDS: {
              additional: true,
              auth: true,
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Clear input fields"),
              description: s_(
                "DastProfiles|Disables clearing of username and password fields before attempting manual login. " \
                  "Set to false by default."
              )
            },
            DAST_AUTH_COOKIE_NAMES: {
              additional: true,
              auth: true,
              type: "string",
              example: "sessionID,groupName",
              name: s_("DastProfiles|Cookie names"),
              description: s_(
                "DastProfiles|Set to a comma-separated list of cookie names to specify which cookies " \
                  "are used for authentication."
              )
            },
            DAST_AUTH_FIRST_SUBMIT_FIELD: {
              additional: true,
              auth: true,
              type: "selector",
              example: "css:input[type=submit]",
              name: s_("DastProfiles|First submit field"),
              description: s_(
                "DastProfiles|A selector describing the element that is clicked on to submit the username form " \
                  "of a multi-page login process."
              )
            },
            DAST_AUTH_NEGOTIATE_DELEGATION: {
              additional: true,
              auth: true,
              type: "string",
              example: "*.example.com,example.com,*.EXAMPLE.COM,EXAMPLE.COM",
              name: s_("DastProfiles|Authentication delegation servers"),
              description: s_(
                "DastProfiles|Which servers should be allowed for integrated authentication and delegation. " \
                  "This property sets two Chromium policies: " \
                  "[AuthServerAllowlist](https://chromeenterprise.google/policies/#AuthServerAllowlist) and " \
                  "[AuthNegotiateDelegateAllowlist]" \
                  "(https://chromeenterprise.google/policies/#AuthNegotiateDelegateAllowlist). " \
                  "[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/502476) in GitLab 17.6."
              )
            },
            DAST_AUTH_PASSWORD: {
              additional: false,
              auth: true,
              type: "String",
              example: "P@55w0rd!",
              name: s_("DastProfiles|Password"),
              description: s_("DastProfiles|The password to authenticate to in the website.")
            },
            DAST_AUTH_PASSWORD_FIELD: {
              additional: false,
              auth: true,
              type: "selector",
              example: "name:password",
              name: s_("DastProfiles|Password field"),
              description: s_(
                "DastProfiles|A selector describing the element used to enter the password on the login form."
              )
            },
            DAST_AUTH_SUBMIT_FIELD: {
              additional: false,
              auth: true,
              type: "selector",
              example: "css:input[type=submit]",
              name: s_("DastProfiles|Submit field"),
              description: s_(
                "DastProfiles|A selector describing the element clicked on to submit the login form " \
                  "for a single-page login form, or the password form for a multi-page login form."
              )
            },
            DAST_AUTH_SUCCESS_IF_AT_URL: {
              additional: true,
              auth: true,
              type: "URL",
              example: "https://www.site.com/welcome",
              name: s_("DastProfiles|Success URL"),
              description: s_(
                "DastProfiles|A URL that is compared to the URL in the browser to determine if authentication " \
                  "has succeeded after the login form is submitted."
              )
            },
            DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND: {
              additional: true,
              auth: true,
              type: "selector",
              example: "css:.user-avatar",
              name: s_("DastProfiles|Success element"),
              description: s_(
                "DastProfiles|A selector describing an element whose presence is used to determine if " \
                  "authentication has succeeded after the login form is submitted."
              )
            },
            DAST_AUTH_SUCCESS_IF_NO_LOGIN_FORM: {
              additional: true,
              auth: true,
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Success without login form"),
              description: s_(
                "DastProfiles|Verifies successful authentication by checking for the absence of a login form " \
                  "after the login form has been submitted. This success check is enabled by default."
              )
            },
            DAST_AUTH_TYPE: {
              additional: true,
              auth: true,
              type: "string",
              example: "basic-digest",
              name: s_("DastProfiles|Authentication type"),
              description: s_("DastProfiles|The authentication type to use.")
            },
            DAST_AUTH_URL: {
              additional: false,
              auth: true,
              type: "URL",
              example: "https://www.site.com/login",
              name: s_("DastProfiles|Authentication URL"),
              description: s_(
                "DastProfiles|The URL of the page containing the login form on the target website. " \
                  "DAST_AUTH_USERNAME and DAST_AUTH_PASSWORD are submitted with the login form to create " \
                  "an authenticated scan."
              )
            },
            DAST_AUTH_USERNAME: {
              additional: false,
              auth: true,
              type: "string",
              example: "user@email.com",
              name: s_("DastProfiles|Username"),
              description: s_("DastProfiles|The username to authenticate to in the website.")
            },
            DAST_AUTH_USERNAME_FIELD: {
              additional: false,
              auth: true,
              type: "selector",
              example: "name:username",
              name: s_("DastProfiles|Username field"),
              description: s_(
                "DastProfiles|A selector describing the element used to enter the username on the login form."
              )
            },
            DAST_CRAWL_EXTRACT_ELEMENT_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "5s",
              name: s_("DastProfiles|Extract element timeout"),
              description: s_(
                "DastProfiles|The maximum amount of time to allow the browser to extract newly found elements " \
                  "or navigations. Defaults to `5s`."
              )
            },
            DAST_CRAWL_MAX_ACTIONS: {
              additional: true,
              type: "number",
              example: "10000",
              name: s_("DastProfiles|Maximum action count"),
              description: s_(
                "DastProfiles|The maximum number of actions that the crawler performs. " \
                  "Example actions include selecting a link, or filling out a form. " \
                  "Defaults to `10000`."
              )
            },
            DAST_CRAWL_MAX_DEPTH: {
              additional: true,
              type: "number",
              example: "10",
              name: s_("DastProfiles|Maximum action depth"),
              description: s_(
                "DastProfiles|The maximum number of chained actions that the crawler takes. " \
                  "For example, `Click, Form Fill, Click` is a depth of three. " \
                  "Defaults to `10`."
              )
            },
            DAST_CRAWL_SEARCH_ELEMENT_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "3s",
              name: s_("DastProfiles|Element search timeout"),
              description: s_(
                "DastProfiles|The maximum amount of time to allow the browser to search for new elements " \
                  "or user actions. Defaults to `3s`."
              )
            },
            DAST_CRAWL_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "5m",
              name: s_("DastProfiles|Timeout"),
              description: s_(
                "DastProfiles|The maximum amount of time to wait for the crawl phase of the scan to complete. " \
                  "Defaults to `24h`."
              )
            },
            DAST_CRAWL_WORKER_COUNT: {
              additional: true,
              type: "number",
              example: "3",
              name: s_("DastProfiles|Worker count"),
              description: s_(
                "DastProfiles|The maximum number of concurrent browser instances to use. " \
                  "For instance runners on GitLab.com, we recommended a maximum of three. " \
                  "Private runners with more resources may benefit from a higher number, " \
                  "but are likely to produce little benefit after five to seven instances. " \
                  "The default value is dynamic, equal to the number of usable logical CPUs."
              )
            },
            DAST_PAGE_DOM_READY_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "7s",
              name: s_("DastProfiles|DOM ready timeout"),
              description: s_(
                "DastProfiles|The maximum amount of time to wait for a browser to consider a page loaded " \
                  "and ready for analysis after a navigation completes. Defaults to `6s`."
              )
            },
            DAST_PAGE_DOM_STABLE_WAIT: {
              additional: true,
              type: "Duration string",
              example: "200ms",
              name: s_("DastProfiles|DOM stable timeout"),
              description: s_(
                "DastProfiles|Define how long to wait for updates to the DOM before checking a page is stable. " \
                  "Defaults to `500ms`."
              )
            },
            DAST_PAGE_ELEMENT_READY_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "600ms",
              name: s_("DastProfiles|Page ready timeout"),
              description: s_(
                "DastProfiles|The maximum amount of time to wait for an element before determining it is " \
                  "ready for analysis. Defaults to `300ms`."
              )
            },
            DAST_PAGE_IS_LOADING_ELEMENT: {
              additional: true,
              type: "selector",
              example: "css:#page-is-loading",
              name: s_("DastProfiles|Loading element"),
              description: s_(
                "DastProfiles|Selector that, when no longer visible on the page, indicates to the analyzer " \
                  "that the page has finished loading and the scan can continue. " \
                  "Cannot be used with `DAST_PAGE_IS_READY_ELEMENT`."
              )
            },
            DAST_PAGE_IS_READY_ELEMENT: {
              additional: true,
              type: "selector",
              example: "css:#page-is-ready",
              name: s_("DastProfiles|Ready element"),
              description: s_(
                "DastProfiles|Selector that when detected as visible on the page, indicates to the analyzer " \
                  "that the page has finished loading and the scan can continue. " \
                  "Cannot be used with `DAST_PAGE_IS_LOADING_ELEMENT`."
              )
            },
            DAST_PAGE_MAX_RESPONSE_SIZE_MB: {
              additional: true,
              type: "number",
              example: "15",
              name: s_("DastProfiles|Maximum response size (MB)"),
              description: s_(
                "DastProfiles|The maximum size of a HTTP response body. " \
                  "Responses with bodies larger than this are blocked by the browser. " \
                  "Defaults to `10` MB."
              )
            },
            DAST_PAGE_READY_AFTER_ACTION_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "7s",
              name: s_("DastProfiles|Page ready timeout (after action)"),
              description: s_(
                "DastProfiles|The maximum amount of time to wait for a browser to consider a page loaded " \
                  "and ready for analysis. Defaults to `7s`."
              )
            },
            DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT: {
              additional: true,
              type: "Duration string",
              example: "15s",
              name: s_("DastProfiles|Page ready timeout (after navigation)"),
              description: s_(
                "DastProfiles|The maximum amount of time to wait for a browser to navigate from one page " \
                  "to another. Defaults to `15s`."
              )
            },
            DAST_PASSIVE_SCAN_WORKER_COUNT: {
              additional: true,
              type: "int",
              example: "5",
              name: s_("DastProfiles|Passive scan worker count"),
              description: s_(
                "DastProfiles|Number of workers that passive scan in parallel. " \
                  "Defaults to the number of available CPUs."
              )
            },
            DAST_PKCS12_CERTIFICATE_BASE64: {
              additional: true,
              type: "string",
              example: "ZGZkZ2p5NGd...",
              name: s_("DastProfiles|PKCS12 certificate"),
              description: s_(
                "DastProfiles|The PKCS12 certificate used for sites that require Mutual TLS. " \
                  "Must be encoded as base64 text."
              )
            },
            DAST_PKCS12_PASSWORD: {
              additional: true,
              type: "string",
              example: "password",
              name: s_("DastProfiles|PKCS12 password"),
              description: format(s_(
                "DastProfiles|The password of the certificate used in `DAST_PKCS12_CERTIFICATE_BASE64`. " \
                  "Create sensitive [custom CI/CI variables](%{documentation_link}) using the GitLab UI."),
                documentation_link: ci_variables_documentation_link
              )
            },
            DAST_REQUEST_ADVERTISE_SCAN: {
              additional: true,
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Advertise scan"),
              description: format(s_(
                "DastProfiles|Set to `true` to add a `Via: GitLab DAST %{version}` header to every request sent, " \
                  "advertising that the request was sent as part of a GitLab DAST scan. Default: `false`."
              ), version: "<version>")
            },
            DAST_REQUEST_COOKIES: {
              additional: true,
              type: "dictionary",
              example: "abtesting_group:3,region:locked",
              name: s_("DastProfiles|Request cookies"),
              description: s_("DastProfiles|A cookie name and value to be added to every request.")
            },
            DAST_REQUEST_HEADERS: {
              additional: false,
              type: "String",
              example: "Cache-control:no-cache",
              name: s_("DastProfiles|Request headers"),
              description: s_(
                "DastProfiles|Set to a comma-separated list of request header names and values. " \
                  "The following headers are not supported: `content-length`, `cookie2`, `keep-alive`, `hosts`, " \
                  "`trailer`, `transfer-encoding`, and all headers with a `proxy-` prefix."
              )
            },
            DAST_SCOPE_ALLOW_HOSTS: {
              additional: true,
              type: "List of strings",
              example: "site.com,another.com",
              name: s_("DastProfiles|Allowed hosts"),
              description: s_(
                "DastProfiles|Hostnames included in this variable are considered in scope when crawled. " \
                  "By default the `DAST_TARGET_URL` hostname is included in the allowed hosts list. " \
                  "Headers set using `DAST_REQUEST_HEADERS` are added to every request made to these hostnames."
              )
            },
            DAST_SCOPE_EXCLUDE_ELEMENTS: {
              additional: true,
              type: "selector",
              example: "a[href='2.html'],css:.no-follow",
              name: s_("DastProfiles|Excluded elements"),
              description: s_("DastProfiles|Comma-separated list of selectors that are ignored when scanning.")
            },
            DAST_SCOPE_EXCLUDE_HOSTS: {
              additional: true,
              type: "List of strings",
              example: "site.com,another.com",
              name: s_("DastProfiles|Excluded hosts"),
              description: s_(
                "DastProfiles|Hostnames included in this variable are considered excluded and connections " \
                  "are forcibly dropped."
              )
            },
            DAST_SCOPE_EXCLUDE_URLS: {
              auth: true,
              additional: false,
              type: "URLs",
              example: "https://site.com/.*/sign-out",
              name: s_("DastProfiles|Excluded URLs"),
              description: s_(
                "DastProfiles|The URLs to skip during the authenticated scan; comma-separated. " \
                  "Regular expression syntax can be used to match multiple URLs. " \
                  "For example, `.*` matches an arbitrary character sequence."
              )
            },
            DAST_SCOPE_IGNORE_HOSTS: {
              additional: true,
              type: "List of strings",
              example: "site.com,another.com",
              name: s_("DastProfiles|Ignored hosts"),
              description: s_(
                "DastProfiles|Hostnames included in this variable are accessed, not attacked, " \
                  "and not reported against."
              )
            },
            DAST_TARGET_CHECK_SKIP: {
              additional: true,
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Skip target check"),
              description: s_(
                "DastProfiles|Set to `true` to prevent DAST from checking that the target is available " \
                  "before scanning. Default: `false`."
              )
            },
            DAST_TARGET_CHECK_TIMEOUT: {
              additional: true,
              type: "number",
              example: "60",
              name: s_("DastProfiles|Target check timeout"),
              description: s_("DastProfiles|Time limit in seconds to wait for target availability. Default: `60s`.")
            },
            DAST_TARGET_PATHS_FILE: {
              additional: true,
              type: "string",
              example: "/builds/project/urls.txt",
              name: s_("DastProfiles|Target paths file"),
              description: s_(
                "DastProfiles|Ensures that the provided paths are always scanned. " \
                  "Set to a file path containing a list of URL paths relative to `DAST_TARGET_URL`. " \
                  "The file must be plain text with one path per line."
              )
            },
            DAST_TARGET_PATHS: {
              additional: true,
              type: "string",
              example: "/page1.html,/category1/page3.html",
              name: s_("DastProfiles|Target paths"),
              description: s_(
                "DastProfiles|Ensures that the provided paths are always scanned. " \
                  "Set to a comma-separated list of URL paths relative to `DAST_TARGET_URL`."
              )
            },
            DAST_TARGET_URL: {
              additional: false,
              type: "URL",
              example: "https://site.com",
              name: s_("DastProfiles|Target URL"),
              description: s_("DastProfiles|The URL of the website to scan.")
            },
            DAST_USE_CACHE: {
              additional: true,
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Use cache"),
              description: s_(
                "DastProfiles|Set to `false` to disable caching. " \
                  "Default: `true`. " \
                  "**Note:** Disabling cache can cause OOM events or DAST job timeouts."
              )
            }
          },
          scanner: {
            DAST_AUTH_REPORT: {
              auth: true,
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Generate authentication report"),
              description: s_(
                "DastProfiles|Set to `true` to generate a report detailing steps taken during the " \
                  "authentication process. You must also define `gl-dast-debug-auth-report.html` as a " \
                  "CI job artifact to be able to access the generated report. " \
                  "The report's content aids when debugging authentication failures. Defaults to `false`."
              )
            },
            DAST_CHECKS_TO_EXCLUDE: {
              type: "string",
              example: "552.2,78.1",
              name: s_("DastProfiles|Excluded checks"),
              description: s_(
                "DastProfiles|Comma-separated list of check identifiers to exclude from the scan. " \
                  "For identifiers, see [vulnerability checks](../checks/_index.md)."
              )
            },
            DAST_CHECKS_TO_RUN: {
              type: "List of strings",
              example: "16.1,16.2,16.3",
              name: s_("DastProfiles|Included checks"),
              description: s_(
                "DastProfiles|Comma-separated list of check identifiers to use for the scan. " \
                  "For identifiers, see [vulnerability checks](../checks/_index.md)."
              )
            },
            DAST_CRAWL_GRAPH: {
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Generate graph"),
              description: s_(
                "DastProfiles|Set to `true` to generate an SVG graph of navigation paths visited during crawl phase " \
                  "of the scan. You must also define `gl-dast-crawl-graph.svg` as a CI job artifact to be able to " \
                  "access the generated graph. Defaults to `false`."
              )
            },
            DAST_FULL_SCAN: {
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Full scan"),
              description: s_("DastProfiles|Set to `true` to run both passive and active checks. Default is `false`.")
            },
            DAST_LOG_BROWSER_OUTPUT: {
              type: "boolean",
              example: true,
              name: s_("DastProfiles|Log browser output"),
              description: s_("DastProfiles|Set to `true` to log Chromium `STDOUT` and `STDERR`.")
            },
            DAST_LOG_CONFIG: {
              type: "List of strings",
              example: "brows:debug,auth:debug",
              name: s_("DastProfiles|Log levels"),
              description: s_(
                "DastProfiles|A list of modules and their intended logging level for use in the console log.")
            },
            DAST_LOG_DEVTOOLS_CONFIG: {
              type: "string",
              example: "Default:messageAndBody,truncate:2000",
              name: s_("DastProfiles|Log messages"),
              description: s_("DastProfiles|Set to log protocol messages between DAST and the Chromium browser.")
            },
            DAST_LOG_FILE_CONFIG: {
              type: "List of strings",
              example: "brows:debug,auth:debug",
              name: s_("DastProfiles|Log file levels"),
              description: s_(
                "DastProfiles|A list of modules and their intended logging level for use in the file log.")
            },
            DAST_LOG_FILE_PATH: {
              type: "string",
              example: "/output/browserker.log",
              name: s_("DastProfiles|Log file path"),
              description: s_("DastProfiles|Set to the path of the file log. Default is `gl-dast-scan.log`.")
            },
            SECURE_ANALYZERS_PREFIX: {
              type: "URL",
              example: "registry.organization.com",
              name: s_("DastProfiles|Docker registry"),
              description: s_("DastProfiles|Set the Docker registry base address from which to download the analyzer.")
            },
            SECURE_LOG_LEVEL: {
              type: "string",
              example: "debug",
              name: s_("DastProfiles|Default log level"),
              description: s_(
                "DastProfiles|Set the default level for the file log. " \
                  "See [SECURE_LOG_LEVEL](../troubleshooting.md#secure_log_level)." \
              )
            }
          }
        }.freeze
      end
      # rubocop: enable Metrics/AbcSize

      def self.additional_site_variables
        data[:site].filter { |_, variable| variable[:additional] }
      end

      def self.auth_variables
        data[:site].merge(data[:scanner]).filter { |_, variable| variable[:auth] }
      end
    end
  end
end
