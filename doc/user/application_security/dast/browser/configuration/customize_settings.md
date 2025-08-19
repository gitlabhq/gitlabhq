---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize analyzer settings
---

## Managing scope

Scope controls what URLs DAST follows when crawling the target application. Properly managed scope minimizes scan run time while ensuring only the target application is checked for vulnerabilities.

### Types of scope

There are three types of scope:

- in scope
- out of scope
- excluded from scope

#### In scope

DAST follows in-scope URLs and searches the DOM for subsequent actions to perform to continue the crawl.
Recorded in-scope HTTP messages are passively checked for vulnerabilities and used to build attacks when running a full scan.

#### Out of scope

DAST follows out-of-scope URLs for non-document content types such as image, stylesheet, font, script, or AJAX request.
[Authentication](#scope-works-differently-during-authentication) aside, DAST does not follow out-of-scope URLs for full page loads, such as when clicking a link to an external website.
Except for passive checks that search for information leaks, recorded HTTP messages for out-of-scope URLs are not checked for vulnerabilities.

#### Excluded from scope

DAST does not follow excluded-from-scope URLs. Except for passive checks that search for information leaks, recorded HTTP messages for excluded-from-scope URLs are not checked for vulnerabilities.

### Scope works differently during authentication

Many target applications have an authentication process that depends on external websites, such as when using an identity access management provider for single sign on (SSO).
To ensure that DAST can authenticate with these providers, DAST follows out-of-scope URLs for full page loads during authentication. DAST does not follow excluded-from-scope URLs.

### How DAST blocks HTTP requests

DAST instructs the browser to make the HTTP request as usual when blocking a request due to scope rules. The request is subsequently intercepted and rejected with the reason `BlockedByClient`.
This approach allows DAST to record the HTTP request while ensuring it never reaches the target server. Passive checks such as [200.1](../checks/200.1.md) use these recorded requests to verify information sent to external hosts.

### How to configure scope

By default, URLs matching the host of the target application are considered in-scope. All other hosts are considered out-of-scope.

Scope is configured using the following variables:

- Use `DAST_SCOPE_ALLOW_HOSTS` to add in-scope hosts.
- Use `DAST_SCOPE_IGNORE_HOSTS` to add to out-of-scope hosts.
- Use `DAST_SCOPE_EXCLUDE_HOSTS` to add to excluded-from-scope hosts.
- Use `DAST_SCOPE_EXCLUDE_URLS` to set specific URLs to be excluded-from-scope.

Rules:

- Excluding a host is given priority over ignoring a host, which is given priority over allowing a host.
- Configuring scope for a host does not configure scope for the subdomains of that host.
- Configuring scope for a host does not configure scope for all ports on that host.

The following could be a typical configuration:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://my.site.com"                   # my.site.com URLs are considered in-scope by default
    DAST_SCOPE_ALLOW_HOSTS: "api.site.com:8443"       # include the API as part of the scan
    DAST_SCOPE_IGNORE_HOSTS: "analytics.site.com"      # explicitly disregard analytics from the scan
    DAST_SCOPE_EXCLUDE_HOSTS: "ads.site.com"           # don't visit any URLs on the ads subdomain
    DAST_SCOPE_EXCLUDE_URLS: "https://my.site.com/user/logout"  # don't visit this URL
```

## Vulnerability detection

DAST detects vulnerabilities through our comprehensive [browser-based vulnerability checks](../checks/_index.md). These checks identify security issues in your web applications during scanning.

The crawler runs the target website in a browser with DAST configured as the proxy server. This
ensures that all requests and responses made by the browser are passively scanned by DAST. When
running a full scan, active vulnerability checks executed by DAST do not use a browser. This
difference in how vulnerabilities are checked can cause issues that require certain features of the
target website to be disabled to ensure the scan works as intended.

For example, for a target website that contains forms with Anti-CSRF tokens, a passive scan works as
intended because the browser displays pages and forms as if a user is viewing the page. However,
active vulnerability checks that run in a full scan cannot submit forms containing Anti-CSRF tokens.
In such cases, we recommend you disable Anti-CSRF tokens when running a full scan.

## Managing scan time

It is expected that running the browser-based crawler results in better coverage for many web applications, when compared to the standard GitLab DAST solution.
This can come at a cost of increased scan time.

You can manage the trade-off between coverage and scan time with the following measures:

- Vertically scale the runner and use a higher number of browsers with the [variable](variables.md) `DAST_CRAWL_WORKER_COUNT`. The default is dynamically set to the number of usable logical CPUs.
- Limit the number of actions executed by the browser with the [variable](variables.md) `DAST_CRAWL_MAX_ACTIONS`. The default is `10,000`.
- Limit the page depth that the browser-based crawler checks coverage on with the [variable](variables.md) `DAST_CRAWL_MAX_DEPTH`. The crawler uses a breadth-first search strategy, so pages with smaller depth are crawled first. The default is `10`.
- Limit the time taken to crawl the target application with the [variable](variables.md) `DAST_CRAWL_TIMEOUT`. The default is `24h`. Scans continue with passive and active checks when the crawler times out.
- Build the crawl graph with the [variable](variables.md) `DAST_CRAWL_GRAPH` to see what pages are being crawled.
- Prevent pages from being crawled using the [variable](variables.md) `DAST_SCOPE_EXCLUDE_URLS`.
- Prevent elements being selected using the [variable](variables.md) `DAST_SCOPE_EXCLUDE_ELEMENTS`. Use with caution, as defining this variable causes an extra lookup for each page crawled.
- If the target application has minimal or fast rendering, consider reducing the [variable](variables.md) `DAST_PAGE_DOM_STABLE_WAIT` to a smaller value. The default is `500ms`.

## Timeouts

Due to poor network conditions or heavy application load, the default timeouts may not be applicable to your application.

Browser-based scans offer the ability to adjust various timeouts to ensure it continues smoothly as it transitions from one page to the next. These values are configured using a [Duration string](https://pkg.go.dev/time#ParseDuration), which allow you to configure durations with a prefix: `m` for minutes, `s` for seconds, and `ms` for milliseconds.

Navigations, or the act of loading a new page, usually require the most amount of time because they are
loading multiple new resources such as JavaScript or CSS files. Depending on the size of these resources, or the speed at which they are returned, the default `DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT` may not be sufficient.

Stability timeouts, such as those configurable with `DAST_PAGE_DOM_READY_TIMEOUT` or `DAST_PAGE_READY_AFTER_ACTION_TIMEOUT`, can also be configured. Stability timeouts determine when browser-based scans consider
a page fully loaded. Browser-based scans consider a page loaded when:

1. The [DOMContentLoaded](https://developer.mozilla.org/en-US/docs/Web/API/Document/DOMContentLoaded_event) event has fired.
1. There are no open or outstanding requests that are deemed important, such as JavaScript and CSS. Media files are usually deemed unimportant.
1. Depending on whether the browser executed a navigation, was forcibly transitioned, or action:

   - There are no new Document Object Model (DOM) modification events after the `DAST_PAGE_DOM_READY_TIMEOUT` or `DAST_PAGE_READY_AFTER_ACTION_TIMEOUT` durations.

After these events have occurred, browser-based scans consider the page loaded and ready, and attempt the next action.

If your application experiences latency or returns many navigation failures, consider adjusting the timeout values such as in this example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://my.site.com"
    DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT: "45s"
    DAST_PAGE_READY_AFTER_ACTION_TIMEOUT: "15s"
    DAST_PAGE_DOM_READY_TIMEOUT: "15s"
```

{{< alert type="note" >}}

Adjusting these values may impact scan time because they adjust how long each browser waits for various activities to complete.

{{< /alert >}}

### Page readiness timeouts

Page readiness refers to the state when a page has loaded completely, its DOM has stabilized, and interactive elements are available. Proper page readiness detection is crucial for:

- **Scanning accuracy**: Analyzing pages before they're fully loaded can miss content or produce false negatives.
- **Crawl efficiency**: Waiting too long wastes scanning time, while not waiting enough misses dynamic content.
- **Modern web application support**: Single-page applications, AJAX-heavy sites, and progressive loading patterns require sophisticated readiness detection.

Using a sequence of optional configurable timeouts, the DAST scanner can detect when different parts of a page have loaded completely.

#### Timeout variables

Use the following CI/CD variables to customize DAST page readiness timeouts.
For a comprehensive list, see [Available CI/CD variables](variables.md).

| Timeout Variable | Default | Description |
|:-----------------|:--------|:------------|
| `DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT` | `15s` | The maximum amount of time to wait for a browser to navigate from one page to another. Used during the Document Load phase for full page loads. |
| `DAST_PAGE_READY_AFTER_ACTION_TIMEOUT` | `7s` | The maximum amount of time to wait for a browser to consider a page loaded and ready for analysis. Used as an alternative to `DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT` for in-page actions that don't trigger a full page load. |
| `DAST_PAGE_DOM_STABLE_WAIT` | `500ms` | Define how long to wait for updates to the DOM before checking a page is stable. Used at the beginning of the client-side render phase. |
| `DAST_PAGE_DOM_READY_TIMEOUT` | `6s` | The maximum amount of time to wait for a browser to consider a page loaded and ready for analysis after a navigation completes. Controls waiting for background data fetching and DOM rendering. |
| `DAST_PAGE_IS_LOADING_ELEMENT` | None | Selector that when no longer visible on the page, indicates to the analyzer that the page has finished loading and the scan can continue. Marks the end of the client-side render process. |

#### Page loading workflow

Modern web applications load in multiple stages. The DAST scanner has specific timeouts for
each step in the process:

1. **Document loading**: The browser fetches and processes the basic page structure.

   1. Fetch HTML content from the server.
   1. Load referenced CSS and JavaScript files.
   1. Parse content and renders the initial page.
   1. Trigger the standard "document ready" event.

   This phase uses either `DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT` (for full page loads) or `DAST_PAGE_READY_AFTER_ACTION_TIMEOUT` (for in-page actions), which sets the maximum wait time for document loading.

1. **Client-Side rendering**: After initial loading, many single-page applications:

   - Perform initial JavaScript execution (`DAST_PAGE_DOM_STABLE_WAIT`).
   - Fetch background data with AJAX or other API calls.
   - Render a DOM and performs updates based on fetched data (`DAST_PAGE_DOM_READY_TIMEOUT`).
   - Display page loading indicators (`DAST_PAGE_IS_LOADING_ELEMENT`).

   The scanner monitors these activities to determine when the page is ready for interaction.

The following chart illustrates the sequence timeouts used when crawling a page:

```mermaid
%%{init: {
  "gantt": {
    "leftPadding": 250,
    "sectionFontSize": 15,
    "topPadding": 40,
    "fontFamily": "GitLab Sans"
  }
}}%%
gantt
    dateFormat YYYY-MM-DD
    axisFormat
    section       Document load
    DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT  :done, nav1, 2024-01-01, 6d
    Fetch HTML  :active, nav1, 2024-01-01, 3d
    Fetch CSS&JS  :active, nav1, 2024-01-04, 3d
    DocumentReady  :milestone, nav1, 2024-01-07, 0d

    section       Load Data / Client-side render
    DAST_PAGE_DOM_STABLE_WAIT  :done, dom1, 2024-01-07, 3d
    Initial JS Execution :active, dom1, 2024-01-07, 3d
    DAST_PAGE_DOM_READY_TIMEOUT  :done, ready1, 2024-01-10, 4d
    Fetch Data :active, dom1, 2024-01-10, 2d
    Render DOM :active, dom1, 2024-01-10, 2d
    DAST_PAGE_IS_LOADING_ELEMENT  :milestone, load1, 2024-01-14, 0d
```
