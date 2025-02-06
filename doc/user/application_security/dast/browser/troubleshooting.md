---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
title: Troubleshooting
---

The following troubleshooting scenarios have been collected from customer support cases. If you
experience a problem not addressed here, or the information here does not fix your problem, create a
support ticket. For more details, see the [GitLab Support](https://about.gitlab.com/support/) page.

## When something goes wrong

When something goes wrong with a DAST scan, if you have a particular error message then check [known problems](#known-problems).

Otherwise, try to discover the problem by answering the following questions:

- [What is the expected outcome?](#what-is-the-expected-outcome)
- [Is the outcome achievable by a human?](#is-the-outcome-achievable-by-a-human)
- [Any reason why DAST would not work?](#any-reason-why-dast-would-not-work)
- [How does your application work?](#how-does-your-application-work)
- [What is DAST doing?](#what-is-dast-doing)

### What is the expected outcome?

Many users who encounter issues with a DAST scan have a good high-level idea of what they think the scanner should be doing. For example,
it's not scanning particular pages, or it's not selecting a button on the page.

As much as possible, try to isolate the problem to help narrow the search for a solution. For example, take the situation where DAST isn't scanning a particular page.
From where should DAST have found the page? What path did it take to get there? Were there elements on the referring page that DAST should have selected, but did not?

### Is the outcome achievable by a human?

DAST cannot scan an application if a human cannot manually traverse the application.

Knowing the outcome you expect, try to replicate it manually using a browser on your machine. For example:

- Open a new incognito/private browser window.
- Open Developer Tools. Keep an eye on the console for error messages.
  - In Chrome: `View -> Developer -> Developer Tools`.
  - In Firefox: `Tools -> Browser Tools -> Web Developer Tools`.
- If authenticating:
  - Go to the `DAST_AUTH_URL`.
  - Type in the `DAST_AUTH_USERNAME` in the `DAST_AUTH_USERNAME_FIELD`.
  - Type in the `DAST_AUTH_PASSWORD` in the `DAST_AUTH_PASSWORD_FIELD`.
  - Select the `DAST_AUTH_SUBMIT_FIELD`.
- Select links and fill in forms. Navigate to the pages that aren't scanning correctly.
- Observe how your application behaves. Notice if there is anything that might cause problems for an automated scanner.

### Any reason why DAST would not work?

DAST cannot scan correctly when:

- There is a CAPTCHA. Turn these off in the testing environment for the application being scanned.
- It does not have access to the target application. Ensure the GitLab Runner can access the application using the URLs used in the DAST configuration.

### How does your application work?

Understanding how your application works is vital to figuring out why a DAST scan isn't working. For example, the following situations
may require additional configuration settings.

- Is there a popup modal that hides elements?
- Does a loaded page change dramatically after a certain period of time?
- Is the application especially slow or fast to load?
- Is the target application jerky while loading?
- Does the application work differently based on the client's location?
- Is the application a single-page application?
- Does the application submit HTML forms, or does it use JavaScript and AJAX?
- Does the application use websockets?
- Does the application use a specific web framework?
- Does selecting buttons run JavaScript before continuing the form submit? Is it fast, slow?
- Is it possible DAST could be selecting or searching for elements before either the element or page is ready?

### What is DAST doing?

Logging remains the best way to understand what DAST is doing:

- [Browser-based analyzer logging](#browser-based-analyzer-logging), useful for understanding what the analyzer is doing.
- [Chromium DevTools logging](#chromium-devtools-logging), useful to inspect the communication between DAST and Chromium.
- [Chromium Logs](#chromium-logs), useful for logging errors when Chromium crashes unexpectedly.

## Browser-based analyzer logging

The analyzer log is one of the most useful tools to help diagnose problems with a scan. Different parts of the analyzer can be logged at different levels.

### Log message format

Log messages have the format `[time] [log level] [log module] [message] [additional properties]`.

For example, the following log entry has level `INFO`, is part of the `CRAWL` log module, has the message `Crawled path` and the additional properties `nav_id` and `path`.

```txt
2021-04-21T00:34:04.000 INF CRAWL Crawled path nav_id=0cc7fd path="LoadURL [https://my.site.com:8090]"
```

### Log destination

Logs are sent either to file or to console (the CI/CD job log). You can configure each destination to accept different logs using
the environment variables `DAST_LOG_CONFIG` for console logs and `DAST_LOG_FILE_CONFIG` for file logs.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_BROWSER_SCAN: "true"
    DAST_LOG_CONFIG: "auth:debug"                               # console log defaults to INFO level, logs AUTH module at DEBUG
    DAST_LOG_FILE_CONFIG: "loglevel:debug,cache:warn"           # file log defaults to DEBUG level, logs CACHE module at WARN
```

By default, the file log is a job artifact called `gl-dast-scan.log`.
To [configure this path](configuration/variables.md), modify the `DAST_LOG_FILE_PATH` CI/CD variable.

### Log levels

The log levels that can be configured are as follows:

| Log module              | Component overview                                                       | More                             |
|-------------------------|--------------------------------------------------------------------------|----------------------------------|
| `TRACE`                 | Used for specific, often noisy inner workings of a feature.              |                                  |
| `DEBUG`                 | Describes the inner-workings of a feature. Used for diagnostic purposes. |                                  |
| `INFO`                  | Describes the high level flow of the scan and the results.               | Default level if none specified. |
| `WARN`                  | Describes an error situation where DAST recovers and continues the scan. |                                  |
| `FATAL`/`ERROR`/`PANIC` | Describes unrecoverable errors prior to exit.                            |                                  |

### Log modules

`LOGLEVEL` configures the default log level for the log destination. If any of the following modules are configured,
DAST uses the log level for that module in preference to the default log level.

The modules that can be configured for logging are as follows:

| Log module | Component overview                                                                                |
|------------|---------------------------------------------------------------------------------------------------|
| `ACTIV`    | Used for active attacks.                                                                          |
| `AUTH`     | Used for creating an authenticated scan.                                                          |
| `BPOOL`    | The set of browsers that are leased out for crawling.                                             |
| `BROWS`    | Used for querying the state or page of the browser.                                               |
| `CACHE`    | Used for reporting on cache hit and miss for cached HTTP resources.                               |
| `CHROM`    | Used to log Chrome DevTools messages.                                                             |
| `CONFG`    | Used to log the analyzer configuration.                                                           |
| `CONTA`    | Used for the container that collects parts of HTTP requests and responses from DevTools messages. |
| `CRAWL`    | Used for the core crawler algorithm.                                                              |
| `CRWLG`    | Used for the crawl graph generator.                                                               |
| `DATAB`    | Used for persisting data to the internal database.                                                |
| `LEASE`    | Used to create browsers to add them to the browser pool.                                          |
| `MAIN`     | Used for the flow of the main event loop of the crawler.                                          |
| `NAVDB`    | Used for persistence mechanisms to store navigation entries.                                      |
| `REGEX`    | Used for recording performance statistics when running regular expressions.                       |
| `REPT`     | Used for generating reports.                                                                      |
| `STAT`     | Used for general statistics while running the scan.                                               |
| `VLDFN`    | Used for loading and parsing vulnerability definitions.                                           |
| `WEBGW`    | Used to log messages sent to the target application when running active checks.                   |
| `SCOPE`    | Used to log messages related to [scope management](configuration/customize_settings.md#managing-scope). |

### Example - log crawled paths

Set the log module `CRAWL` to `DEBUG` to log navigation paths found during the crawl phase of the scan. This is useful for understanding
if DAST is crawling your target application correctly.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_CONFIG: "crawl:debug"
```

For example, the following output shows that four anchor links we discovered during the crawl of the page at `https://example.com`.

```plaintext
2022-11-17T11:18:05.578 DBG CRAWL executing step nav_id=6ec647d8255c729160dd31cb124e6f89 path="LoadURL [https://example.com]" step=1
...
2022-11-17T11:18:11.900 DBG CRAWL found new navigations browser_id=2243909820020928961 nav_count=4 nav_id=6ec647d8255c729160dd31cb124e6f89 of=1 step=1
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page1.html]" nav=bd458cc1fc2d7c6fb984464b6d968866 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page2.html]" nav=6dcb25f9f9ece3ee0071ac2e3166d8e6 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page3.html]" nav=89efbb0c6154d6c6d85a63b61a7cdc6f parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page4.html]" nav=f29b4f4e0bdee70f5255de7fc080f04d parent_nav=6ec647d8255c729160dd31cb124e6f89
```

## Chromium DevTools logging

WARNING:
Logging DevTools messages is a security risk. The output contains secrets such as usernames, passwords and authentication tokens.
The output is uploaded to the GitLab server and may be visible in job logs.

The DAST Browser-based scanner orchestrates a Chromium browser using the [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/).
Logging DevTools messages helps provide transparency into what the browser is doing. For example, if selecting a button does not work, a DevTools message might show that the cause is a CORS error in a browser console log.
Logs that contain DevTools messages can be very large in size. For this reason, it should only be enabled on jobs with a short duration.

To log all DevTools messages, turn the `CHROM` log module to `trace` and configure logging levels. The following are examples of DevTools logs:

```plaintext
2022-12-05T06:27:24.280 TRC CHROM event received    {"method":"Fetch.requestPaused","params":{"requestId":"interception-job-3.0","request":{"url":"http://auth-auto:8090/font-awesome.min.css","method":"GET","headers":{"Accept":"text/css,*/*;q=0.1","Referer":"http://auth-auto:8090/login.html","User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"},"initialPriority":"VeryHigh","referrerPolicy":"strict-origin-when-cross-origin"},"frameId":"A706468B01C2FFAA2EB6ED365FF95889","resourceType":"Stylesheet","networkId":"39.3"}} method=Fetch.requestPaused
2022-12-05T06:27:24.280 TRC CHROM request sent      {"id":47,"method":"Fetch.continueRequest","params":{"requestId":"interception-job-3.0","headers":[{"name":"Accept","value":"text/css,*/*;q=0.1"},{"name":"Referer","value":"http://auth-auto:8090/login.html"},{"name":"User-Agent","value":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"}]}} id=47 method=Fetch.continueRequest
2022-12-05T06:27:24.281 TRC CHROM response received {"id":47,"result":{}} id=47 method=Fetch.continueRequest
```

### Customizing DevTools log levels

Chrome DevTools requests, responses and events are namespaced by domain. DAST allows each domain and each domain with message to have different logging configuration.
The environment variable `DAST_LOG_DEVTOOLS_CONFIG` accepts a semi-colon separated list of logging configurations.
Logging configurations are declared using the structure `[domain/message]:[what-to-log][,truncate:[max-message-size]]`.

- `domain/message` references what is being logged.
  - `Default` can be used as a value to represent all domains and messages.
  - Can be a domain, for example, `Browser`, `CSS`, `Page`, `Network`.
  - Can be a domain with a message, for example, `Network.responseReceived`.
  - If multiple configurations apply, the most specific configuration is used.
- `what-to-log` references whether and what to log.
  - `message` logs that a message was received and does not log the message content.
  - `messageAndBody` logs the message with the message content. Recommended to be used with `truncate`.
  - `suppress` does not log the message. Used to silence noisy domains and messages.
- `truncate` is an optional configuration to limit the size of the message printed.

### Example - log all DevTools messages

Used to log everything when you're not sure where to start.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:messageAndBody,truncate:2000"
```

### Example - log HTTP messages

Useful for when a resource isn't loading correctly. HTTP message events are logged, as is the decision to continue or
fail the request. Any errors in the browser console are also logged.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:suppress;Fetch:messageAndBody,truncate:2000;Network:messageAndBody,truncate:2000;Log:messageAndBody,truncate:2000;Console:messageAndBody,truncate:2000"
```

## Chromium logs

In the rare event that Chromium crashes, it can be helpful to write the Chromium process `STDOUT` and `STDERR` to log.
Setting the environment variable `DAST_LOG_BROWSER_OUTPUT` to `true` achieves this purpose.

DAST starts and stops many Chromium processes. DAST sends each process output to all log destinations with the log module `LEASE` and log level `INFO`.

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_BROWSER_OUTPUT: "true"
```

## Known problems

### Logs contain `response body exceeds allowed size`

By default DAST processes HTTP requests where the HTTP response body is 10 MB or less. Otherwise, DAST blocks the response
which can cause scans to fail. This constraint is intended to reduce memory consumption during a scan.

An example log is as follows, where DAST blocked the JavaScript file found at `https://example.com/large.js` as it's size is greater than the limit:

```plaintext
2022-12-05T06:28:43.093 WRN BROWS response body exceeds allowed size allowed_size_bytes=1000000 browser_id=752944257619431212 nav_id=ae23afe2acbce2c537657a9112926f1a of=1 request_id=interception-job-2.0 response_size_bytes=9333408 step=1 url=https://example.com/large.js
2022-12-05T06:28:58.104 WRN CONTA request failed, attempting to continue scan error=net::ERR_BLOCKED_BY_RESPONSE index=0 requestID=38.2 url=https://example.com/large.js
```

This can be changed using the configuration `DAST_PAGE_MAX_RESPONSE_SIZE_MB`. For example,

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_PAGE_MAX_RESPONSE_SIZE_MB: "25"
```

### Crawler doesn't reach expected pages

#### Try disabling the cache

If DAST incorrectly caches your application pages, it can lead to DAST being unable to properly crawl your application. If you see that some pages are unexpectedly not found by the crawler, try setting `DAST_USE_CACHE: "false"` variable to see if that helps. Note that it can significantly decrease the performance of the scan. Make sure to only disable cache when absolutely necessary. If you have a subscription, [create a support ticket](https://about.gitlab.com/support/) to investigate why cache is preventing your website from being crawled.

#### Specifying target paths directly

The crawler typically begins at the defined target URL and attempts to find further pages by interacting with the site. However, there are two ways to specify paths directly for the crawler to start from:

- Using a sitemap.xml: [Sitemap](https://www.sitemaps.org/protocol.html) is a well defined protocol to specify the pages in a website. DAST's crawler looks for a sitemap.xml file at `<target URL>/sitemap.xml` and takes all specified URLs as a starting point for the crawler. [Sitemap Index](https://www.sitemaps.org/protocol.html#index) files are not supported.
- Using `DAST_TARGET_PATHS`: This configuration variable allows specifying input paths for the crawler. Example: `DAST_TARGET_PATHS: /,/page/1.html,/page/2.html`.

#### Make sure requests are not getting blocked

By default DAST only allows requests to the target URL's domain. If your website makes requests to domains other than the target's, use `DAST_SCOPE_ALLOW_HOSTS` to specify such hosts. Example: "example.com" makes an authentication request to "auth.example.com" to renew the authentication token. Because the domain is not allowed, the request gets blocked and the crawler fails to find new pages.
