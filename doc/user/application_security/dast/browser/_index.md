---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
title: DAST browser-based analyzer
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/9023) in GitLab 15.7 (GitLab DAST v3.0.50).

WARNING:
The DAST version 4 browser-based analyzer is replaced by DAST version 5 in GitLab 17.0.
For instructions on how to migrate to DAST version 5, see the [migration guide](../browser_based_4_to_5_migration_guide.md).

Browser-based DAST helps you identify security weaknesses (CWEs) in your web applications. After you
deploy your web application, it becomes exposed to new types of attacks, many of which cannot be
detected prior to deployment. For example, misconfigurations of your application server or incorrect
assumptions about security controls may not be visible from the source code, but they can be
detected with browser-based DAST.

Dynamic Application Security Testing (DAST) examines applications for vulnerabilities like these in
deployed environments.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Dynamic Application Security Testing (DAST)](https://www.youtube.com/watch?v=nbeDUoLZJTo).

WARNING:
Do not run DAST scans against a production server. Not only can it perform *any* function that a
user can, such as clicking buttons or submitting forms, but it may also trigger bugs, leading to
modification or loss of production data. Only run DAST scans against a test server.

The DAST browser-based analyzer was built by GitLab to scan modern-day web applications for
vulnerabilities. Scans run in a browser to optimize testing applications heavily dependent on
JavaScript, such as single-page applications. See
[how DAST scans an application](#how-dast-scans-an-application) for more information.

To add the analyzer to your CI/CD pipeline, see [enabling the analyzer](configuration/enabling_the_analyzer.md).

## How DAST scans an application

A scan performs the following steps:

1. [Authenticate](configuration/authentication.md), if configured.
1. [Crawl](#crawling-an-application) the target application to discover the surface area of the application by performing user actions such as following links, clicking buttons, and filling out forms.
1. [Passive scan](#passive-scans) to search for vulnerabilities in HTTP messages and pages discovered while crawling.
1. [Active scan](#active-scans) to search for vulnerabilities by injecting payloads into HTTP requests recorded during the crawl phase.

### Crawling an application

A "navigation" is an action a user might take on a page, such as clicking buttons, clicking anchor links, opening menu items, or filling out forms.
A "navigation path" is a sequence of navigation actions representing how a user might traverse an application.
DAST discovers the surface area of an application by crawling pages and content and identifying navigation paths.

Crawling is initialized with a navigation path containing one navigation that loads the target application URL in a specially-instrumented Chromium browser.
DAST then crawls navigation paths until all have been crawled.

To crawl a navigation path, DAST opens a browser window and instructs it to perform all the navigation actions in the navigation path.
When the browser has finished loading the result of the final action, DAST inspects the page for actions a user might take,
creates a new navigation for each found, and adds them to the navigation path to form new navigation paths. For example:

1. DAST processes navigation path `LoadURL[https://example.com]`.
1. DAST finds two user actions, `LeftClick[class=menu]` and `LeftClick[id=users]`.
1. DAST creates two new navigation paths, `LoadURL[https://example.com] -> LeftClick[class=menu]` and `LoadURL[https://example.com] -> LeftClick[id=users]`.
1. Crawling begins on the two new navigation paths.

It's common for an HTML element to exist in multiple places in an application, such as a menu visible on every page.
Duplicate elements can cause crawlers to crawl the same pages again or become stuck in a loop.
DAST uses an element uniqueness calculation based on HTML attributes to discard new navigation actions it has previously crawled.

### Passive scans

Passive scans check for vulnerabilities in the pages discovered during the crawl phase of the scan.
Passive scans are enabled by default.

The checks search HTTP messages, cookies, storage events, console events, and DOM for vulnerabilities.
Examples of passive checks include searching for exposed credit cards, exposed secret tokens, missing content security policies, and redirection to untrusted locations.

See [checks](checks/_index.md) for more information about individual checks.

### Active scans

Active scans check for vulnerabilities by injecting attack payloads into HTTP requests recorded during the crawl phase of the scan.
Active scans are disabled by default due to the nature of their probing attacks.

DAST analyzes each recorded HTTP request for injection locations, such as query values, header values, cookie values, form posts, and JSON string values.
Attack payloads are injected into the injection location, forming a new request.
DAST sends the request to the target application and uses the HTTP response to determine attack success.

Active scans run two types of active check:

- A match response attack analyzes the response content to determine attack success. For example, if an attack attempts to read the system password file, a finding is created when the response body contains evidence of the password file.
- A timing attack uses the response time to determine attack success. For example, if an attack attempts to force the target application to sleep, a finding is created when the application takes longer to respond than the sleep time. Timing attacks are repeated multiple times with different attack payloads to minimize false positives.

A simplified timing attack works as follows:

1. The crawl phase records the HTTP request `https://example.com?search=people`.
1. DAST analyzes the URL and finds a URL parameter injection location `https://example.com?search=[INJECT]`.
1. The active check defines a payload, `sleep 10`, that attempts to get a Linux host to sleep.
1. DAST send a new HTTP request to the target application with the injected payload `https://example.com?search=sleep%2010`.
1. The target application is vulnerable if it executes the query parameter value as a system command without validation, for example, `system(params[:search])`
1. DAST creates a finding if the response time takes longer than 10 seconds.
