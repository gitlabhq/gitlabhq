---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DAST browser-based analyzer
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/9023) in GitLab 15.7 (GitLab DAST v3.0.50).

{{< /history >}}

{{< alert type="warning" >}}

The DAST version 4 browser-based analyzer is replaced by DAST version 5 in GitLab 17.0.
For instructions on how to migrate to DAST version 5, see the [migration guide](../browser_based_4_to_5_migration_guide.md).

{{< /alert >}}

Browser-based DAST helps you identify security weaknesses (CWEs) in your web applications. After you
deploy your web application, it becomes exposed to new types of attacks, many of which cannot be
detected prior to deployment. For example, misconfigurations of your application server or incorrect
assumptions about security controls may not be visible from the source code, but they can be
detected with browser-based DAST.

Dynamic Application Security Testing (DAST) examines applications for vulnerabilities like these in
deployed environments.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Dynamic Application Security Testing (DAST) - Advanced Security Testing](https://www.youtube.com/watch?v=nbeDUoLZJTo).

{{< alert type="warning" >}}

Do not run DAST scans against a production server. Not only can it perform any function that a
user can, such as clicking buttons or submitting forms, but it may also trigger bugs, leading to
modification or loss of production data. Only run DAST scans against a test server.

{{< /alert >}}

The DAST browser-based analyzer was built by GitLab to scan modern-day web applications for
vulnerabilities. Scans run in a browser to optimize testing applications heavily dependent on
JavaScript, such as single-page applications. See
[how DAST scans an application](#how-dast-scans-an-application) for more information.

To add the analyzer to your CI/CD pipeline, see [enabling the analyzer](configuration/enabling_the_analyzer.md).

## Getting started

If you're new to DAST, get started by enabling it for a project.

Prerequisites:

- You have a [GitLab Runner](../../../../ci/runners/_index.md) with the
  [`docker` executor](https://docs.gitlab.com/runner/executors/docker.html) on Linux/amd64.
- You have a deployed target application. For more details, see the [deployment options](application_deployment_options.md).
- The `dast` stage is added to the CI/CD pipeline definition, after the `deploy` stage. For example:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - dast
  ```

- You have a network connection between the runner and your target application.

  How you connect depends on your DAST configuration:
  - If `DAST_TARGET_URL` and `DAST_AUTH_URL` specify port numbers, use those ports.
  - If ports are not specified, use the standard port numbers for HTTP and HTTPS.

  You might need to open both an HTTP and HTTPS port. For example, if the target URL uses HTTP, but the application links to resources using HTTPS. Always test your connection when you configure a scan.

To enable DAST in a project:

- [Add a DAST job to your CI/CD configuration](configuration/enabling_the_analyzer.md#create-a-dast-cicd-job).

### Target connection issues

Before DAST begins a scan, it checks if the target URL is reachable. If the target URL cannot be reached, DAST produces detailed error messages to help diagnose the issue. By default, DAST retries a connection every two seconds, up to 60 seconds. You can configure when DAST retries a connection with `DAST_TARGET_CHECK_TIMEOUT`.

If you experience connectivity issues:

1. Verify your `DAST_TARGET_URL` configuration.
   - Check for typos in the hostname, port, or protocol.
   - Ensure the URL includes the protocol (`http://` or `https://`).
   - Verify the port number matches where your application is running.

1. Test connectivity from the runner.
   - Test the connection: `curl --verbose "http://your-target-url:port"`
   - Check DNS resolution: `nslookup your-hostname.com`
   - Verify the port is open: `nc -zv your-hostname.com port`

1. Verify your application is running.
   - Check that your application has started successfully.
   - Review application logs for startup errors.
   - Ensure all dependencies, including databases and APIs, are available.

1. Check network and firewall configuration.
   - Ensure firewall rules allow traffic on the required ports.
   - For internal applications, ensure the runner can access internal DNS servers.

1. If your application takes a long time to start or become healthy, increase the timeout:

   ```yaml
      variables:
        DAST_TARGET_CHECK_TIMEOUT: "5m"  # Wait up to 5 minutes
   ```

#### DNS lookup failed

You might see an error like `DNS lookup failed`.
This happens when DAST can't find the server address for the hostname you provided because:

- The hostname in `DAST_TARGET_URL` is misspelled or incorrect.
- The domain hasn't been registered or doesn't exist.
- There are DNS resolution issues in your network or runner environment.

#### Connection refused

You might see an error that says `connection refused`.
This usually happens when the server exists, but:

- The application hasn't finished starting up yet.
- The application is running on a different port than specified.
- A firewall is blocking the connection between the runner and your application.
- The application crashed or failed to start.

#### Target responded with HTTP 5xx error

You might see the target application respond with an `HTTP 5xx` error. This happens when the application is reachable, but is responding with server errors like  `500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable`, or `504 Gateway Timeout`.

You might see server errors when:

- The application is starting up and not fully ready.
- The application has a configuration error.
- Required dependencies, like databases and APIs, aren't available.

## Understanding the results

You can review vulnerabilities in a pipeline:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the left sidebar, select **Build** > **Pipelines**.
1. Select the pipeline.
1. Select the **Security** tab.
1. Select a vulnerability to view its details, including:
   - Status: Indicates whether the vulnerability has been triaged or resolved.
   - Description: Explains the cause of the vulnerability, its potential impact, and recommended remediation steps.
   - Severity: Categorized into six levels based on impact.
     [Learn more about severity levels](../../vulnerabilities/severities.md).
   - Scanner: Identifies which analyzer detected the vulnerability.
   - Method: Establishes the vulnerable server interaction type.
   - URL: Shows the location of the vulnerability.
   - Evidence: Describes test case to prove the presence of a given vulnerability.
   - Identifiers: A list of references used to classify the vulnerability, such as CWE identifiers.

You can also download the security scan results:

- In the pipeline's **Security** tab, select **Download results**.

For more details, see [Pipeline security report](../../detect/security_scanning_results.md).

{{< alert type="note" >}}

Findings are generated on feature branches. When they are merged into the default branch, they become vulnerabilities. This distinction is important when evaluating your security posture.

{{< /alert >}}

## Optimization

For information about configuring DAST for a specific application or environment, see the [configuration options](configuration/_index.md).

## Roll out

After you configure DAST for a single project, you can extend the configuration to other projects:

- Take care if your pipeline is configured to deploy to the same web server in each run. Running a DAST scan while a server is being updated leads to inaccurate and non-deterministic results.
- Configure runners to use the [always pull policy](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy) to run the latest versions of the analyzers.
- By default, DAST downloads all artifacts defined by previous jobs in the pipeline. If
  your DAST job does not rely on `environment_url.txt` to define the URL under test or any other files created
  in previous jobs, you shouldn't download artifacts. To avoid downloading
  artifacts, extend the analyzer CI/CD job to specify no dependencies. For example, for the DAST proxy-based analyzer add the following to your `.gitlab-ci.yml` file:

  ```yaml
  dast:
    dependencies: []
  ```

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
Passive scans attempt to interact with a site in the same way as a normal user, including by performing destructive actions like deleting data.
However, passive scans do not simulate adversarial behavior.
Passive scans are enabled by default.

The checks search HTTP messages, cookies, storage events, console events, and DOM for vulnerabilities.
Examples of passive checks include searching for exposed credit cards, exposed secret tokens, missing content security policies, and redirection to untrusted locations.

See [checks](checks/_index.md) for more information about individual checks.

### Active scans

Active scans check for vulnerabilities by injecting attack payloads into HTTP requests recorded during the crawl phase of the scan.
Active scans are disabled by default because they simulate adversarial behavior.

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
