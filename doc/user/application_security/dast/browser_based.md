---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# DAST browser-based crawler **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323423) in GitLab 13.12.

WARNING:
This product is an early access and is considered a [beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta) feature.

GitLab DAST's new browser-based crawler is a crawl engine built by GitLab to test Single Page Applications (SPAs) and traditional web applications.
Due to the reliance of modern web applications on JavaScript, handling SPAs or applications that are dependent on JavaScript is paramount to ensuring proper coverage of an application for Dynamic Application Security Testing (DAST).

The browser-based crawler works by loading the target application into a specially-instrumented Chromium browser. A snapshot of the page is taken prior to a search to find any actions that a user might perform,
such as clicking on a link or filling in a form. For each action found, the crawler will execute it, take a new snapshot and determine what in the page changed from the previous snapshot.
Crawling continues by taking more snapshots and finding subsequent actions.

The benefit of crawling by following user actions in a browser is that the crawler can interact with the target application much like a real user would, identifying complex flows that traditional web crawlers don’t understand. This results in better coverage of the website.

Using the browser-based crawler should provide greater coverage for most web applications, compared with the current DAST AJAX crawler. The new crawler replaces the AJAX crawler and is specifically designed to maximize crawl coverage in modern web applications. While both crawlers are currently used in conjunction with the existing DAST scanner, the combination of the browser-based crawler with the current DAST scanner is much more effective at finding and testing every page in an application.

## Enable browser-based crawler

The browser-based crawler is an extension to the GitLab DAST product. DAST should be included in the CI/CD configuration and the browser-based crawler enabled using CI/CD variables:

1. Ensure the DAST [prerequisites](index.md#prerequisites) are met.
1. Include the [DAST CI template](index.md#include-the-dast-template).
1. Set the target website using the `DAST_WEBSITE` CI/CD variable.
1. Set the CI/CD variable `DAST_BROWSER_SCAN` to `true`.

An example configuration might look like the following:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_WEBSITE: "https://example.com"
    DAST_BROWSER_SCAN: "true"
```

### Available CI/CD variables

The browser-based crawler can be configured using CI/CD variables.

| CI/CD variable                       | Type            | Example                           | Description |
|--------------------------------------| ----------------| --------------------------------- | ------------|
| `DAST_WEBSITE`                       | URL             | `http://www.site.com`             | The URL of the website to scan. |
| `DAST_BROWSER_SCAN`                  | boolean         | `true`                            | Configures DAST to use the browser-based crawler engine. |
| `DAST_BROWSER_ALLOWED_HOSTS`         | List of strings | `site.com,another.com`            | Hostnames included in this variable are considered in scope when crawled. By default the `DAST_WEBSITE` hostname is included in the allowed hosts list. |
| `DAST_BROWSER_EXCLUDED_HOSTS`        | List of strings | `site.com,another.com`            | Hostnames included in this variable are considered excluded and connections are forcibly dropped. |
| `DAST_BROWSER_IGNORED_HOSTS`         | List of strings | `site.com,another.com`            | Hostnames included in this variable are accessed but not reported against. |
| `DAST_BROWSER_MAX_ACTIONS`           | number          | `10000`                           | The maximum number of actions that the crawler performs. For example, clicking a link, or filling a form.  |
| `DAST_BROWSER_MAX_DEPTH`             | number          | `10`                              | The maximum number of chained actions that the crawler takes. For example, `Click -> Form Fill -> Click` is a depth of three. |
| `DAST_BROWSER_NUMBER_OF_BROWSERS`    | number          | `3`                               | The maximum number of concurrent browser instances to use. For shared runners on GitLab.com we recommended a maximum of three. Private runners with more resources may benefit from a higher number, but will likely produce little benefit after five to seven instances. |
| `DAST_BROWSER_COOKIES`               | dictionary      | `abtesting_group:3,region:locked` | A cookie name and value to be added to every request. |
| `DAST_BROWSER_LOG`                   | List of strings | `brows:debug,auth:debug`          | A list of modules and their intended log level. |

The [DAST variables](index.md#available-cicd-variables) `SECURE_ANALYZERS_PREFIX`, `DAST_FULL_SCAN_ENABLED`, `DAST_AUTO_UPDATE_ADDONS`, `DAST_EXCLUDE_RULES`, `DAST_REQUEST_HEADERS`, `DAST_HTML_REPORT`, `DAST_MARKDOWN_REPORT`, `DAST_XML_REPORT`,
`DAST_AUTH_URL`, `DAST_USERNAME`, `DAST_PASSWORD`, `DAST_USERNAME_FIELD`, `DAST_PASSWORD_FIELD`, `DAST_FIRST_SUBMIT_FIELD`, `DAST_SUBMIT_FIELD`, `DAST_EXCLUDE_URLS`, `DAST_AUTH_VERIFICATION_URL`, `DAST_BROWSER_AUTH_VERIFICATION_SELECTOR`, `DAST_BROWSER_AUTH_VERIFICATION_LOGIN_FORM`, `DAST_BROWSER_AUTH_REPORT`,
`DAST_INCLUDE_ALPHA_VULNERABILITIES`, `DAST_PATHS_FILE`, `DAST_PATHS`, `DAST_ZAP_CLI_OPTIONS`, and `DAST_ZAP_LOG_CONFIGURATION` are also compatible with browser-based crawler scans.

## Vulnerability detection

While the browser-based crawler crawls modern web applications efficiently, vulnerability detection is still managed by the standard DAST/Zed Attack Proxy (ZAP) solution.

The crawler runs the target website in a browser with DAST/ZAP configured as the proxy server. This ensures that all requests and responses made by the browser are passively scanned by DAST/ZAP.
When running a full scan, active vulnerability checks executed by DAST/ZAP do not use a browser. This difference in how vulnerabilities are checked can cause issues that require certain features of the target website to be disabled to ensure the scan works as intended.

For example, for a target website that contains forms with Anti-CSRF tokens, a passive scan will scan as intended because the browser displays pages/forms as if a user is viewing the page.
However, active vulnerability checks run in a full scan will not be able to submit forms containing Anti-CSRF tokens. In such cases we recommend you disable Anti-CSRF tokens when running a full scan.

## Managing scan time

It is expected that running the browser-based crawler will result in better coverage for many web applications, when compared to the normal GitLab DAST solution.
This can come at a cost of increased scan time.

You can manage the trade-off between coverage and scan time with the following measures:

- Limit the number of actions executed by the browser with the [variable](#available-cicd-variables) `DAST_BROWSER_MAX_ACTIONS`. The default is `10,000`.
- Limit the page depth that the browser-based crawler will check coverage on with the [variable](#available-cicd-variables) `DAST_BROWSER_MAX_DEPTH`. The crawler uses a breadth-first search strategy, so pages with smaller depth are crawled first. The default is `10`.
- Vertically scaling the runner and using a higher number of browsers with [variable](#available-cicd-variables) `DAST_BROWSER_NUMBER_OF_BROWSERS`. The default is `3`.

## Debugging scans using logging

Logging can be used to help you troubleshoot a scan.

The CI/CD variable `DAST_BROWSER_LOG` configures the logging level for particular modules of the crawler. Each module represents a component of the browser-based crawler and is separated so that debug logs can be configured just for the area of the crawler that requires further inspection. For more details, see [Crawler modules](#crawler-modules).

For example, the following job definition enables the browsing module and the authentication module to be logged in debug-mode:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_WEBSITE: "https://my.site.com"
    DAST_BROWSER_SCAN: "true"
    DAST_BROWSER_LOG: "brows:debug,auth:debug"
```

### Log message format

Log messages have the format `[time] [log level] [log module] [message] [additional properties]`. For example, the following log entry has level `INFO`, is part of the `CRAWL` log module, and has the message `Crawled path`.

```txt
2021-04-21T00:34:04.000 INF CRAWL Crawled path nav_id=0cc7fd path="LoadURL [https://my.site.com:8090]"
```

### Crawler modules

The modules that can be configured for logging are as follows:

| Log module | Component overview |
| ---------- | ----------- |
| `AUTH`     | Used for creating an authenticated scan. |
| `BROWS`    | Used for querying the state/page of the browser. |
| `BPOOL`    | The set of browsers that are leased out for crawling. |
| `CRAWL`    | Used for the core crawler algorithm. |
| `DATAB`    | Used for persisting data to the internal database. |
| `LEASE`    | Used to create browsers to add them to the browser pool. |
| `MAIN`     | Used for the flow of the main event loop of the crawler. |
| `NAVDB`    | Used for persistence mechanisms to store navigation entries. |
| `REPT`     | Used for generating reports. |
| `STAT`     | Used for general statistics while running the scan. |
