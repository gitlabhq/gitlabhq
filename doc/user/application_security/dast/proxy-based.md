---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
<!--- start_remove The following content will be removed on remove_date: '2024-08-15' -->

# DAST proxy-based analyzer (deprecated)

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

WARNING:
The DAST proxy-based analyzer was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) in GitLab 16.9 and
is replaced by DAST version 5 in GitLab 17.0. This change is a breaking change. For instructions on how to migrate
to DAST version 5, see the [migration guide](proxy_based_to_browser_based_migration_guide.md).

The DAST proxy-based analyzer can be added to your [GitLab CI/CD](../../../ci/index.md) pipeline.
This helps you discover vulnerabilities in web applications that do not use JavaScript heavily. For applications that do,
see the [DAST browser-based analyzer](browser/index.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video walkthrough, see [How to set up Dynamic Application Security Testing (DAST) with GitLab](https://youtu.be/EiFE1QrUQfk?si=6rpgwgUpalw3ByiV).

WARNING:
Do not run DAST scans against a production server. Not only can it perform *any* function that a
user can, such as clicking buttons or submitting forms, but it may also trigger bugs, leading to
modification, or loss of production data. Only run DAST scans against a test server.

The analyzer uses the [Software Security Project Zed Attack Proxy](https://www.zaproxy.org/) (ZAP) to scan in two different ways:

- Passive scan only (default). DAST executes
  [ZAP's Baseline Scan](https://www.zaproxy.org/docs/docker/baseline-scan/) and doesn't
  actively attack your application.
- Passive and active (or full) scan. DAST can be [configured](#full-scan) to also perform an active scan
  to attack your application and produce a more extensive security report. It can be very
  useful when combined with [review apps](../../../ci/review_apps/index.md).

## Templates

> - All DAST templates were [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87183) to DAST_VERSION: 3 in GitLab 15.0.

GitLab DAST configuration is defined in CI/CD templates. Updates to the template are provided with
GitLab upgrades, allowing you to benefit from any improvements and additions.

Available templates:

- [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml): Stable version of the DAST CI/CD template.
- [`DAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml): Latest version of the DAST template.

WARNING:
The latest version of the template may include breaking changes. Use the stable template unless you
need a feature provided only in the latest template.

For more information about template versioning, see the
[CI/CD documentation](../../../development/cicd/templates.md#latest-version).

## DAST versions

By default, the DAST template uses the latest major version of the DAST Docker image. You can choose
how DAST updates, using the `DAST_VERSION` variable:

- Automatically update DAST with new features and fixes by pinning to a major
  version (such as `1`).
- Only update fixes by pinning to a minor version (such as `1.6`).
- Prevent all updates by pinning to a specific version (such as `1.6.4`).

Find the latest DAST versions on the [DAST releases](https://gitlab.com/gitlab-org/security-products/dast/-/releases)
page.

## DAST run options

You can use DAST to examine your web application:

- Automatically, initiated by a merge request.
- Manually, initiated on demand.

Some of the differences between these run options:

| Automatic scan                                                   | On-demand scan                |
|:-----------------------------------------------------------------|:------------------------------|
| DAST scan is initiated by a merge request.                       | DAST scan is initiated manually, outside the DevOps life cycle. |
| CI/CD variables are sourced from `.gitlab-ci.yml`.               | CI/CD variables are provided in the UI. |
| All [DAST CI/CD variables](#available-cicd-variables) available. | Subset of [DAST CI/CD variables](#available-cicd-variables) available. |
| `DAST.gitlab-ci.yml` template.                                   | `DAST-On-Demand-Scan.gitlab-ci.yml` template. |

### Enable automatic DAST run

To enable DAST to run automatically, either:

- Enable [Auto DAST](../../../topics/autodevops/stages.md#auto-dast) (provided
  by [Auto DevOps](../../../topics/autodevops/index.md)).
- [Edit the `.gitlab-ci.yml` file manually](#edit-the-gitlab-ciyml-file-manually).
- [Configure DAST using the UI](#configure-dast-using-the-ui).

#### Edit the `.gitlab-ci.yml` file manually

In this method you manually edit the existing `.gitlab-ci.yml` file. Use this method if your GitLab CI/CD configuration file is complex.

To include the DAST template:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. Copy and paste the following to the bottom of the `.gitlab-ci.yml` file. If an `include` line
   already exists, add only the `template` line below it.

   To use the DAST stable template:

   ```yaml
   include:
     - template: DAST.gitlab-ci.yml
   ```

   To use the DAST latest template:

   ```yaml
   include:
     - template: DAST.latest.gitlab-ci.yml
   ```

1. Define the URL to be scanned by DAST by using one of these methods:

   - Set the `DAST_WEBSITE` [CI/CD variable](../../../ci/yaml/index.md#variables).
     If set, this value takes precedence.

   - Add the URL in an `environment_url.txt` file at the root of your project. This is
     useful for testing in dynamic environments. To run DAST against an application
     dynamically created during a GitLab CI/CD pipeline, a job that runs prior to
     the DAST scan must persist the application's domain in an `environment_url.txt`
     file. DAST automatically parses the `environment_url.txt` file to find its
     scan target.

     For example, in a job that runs prior to DAST, you could include code that
     looks similar to:

     ```yaml
     script:
       - echo http://${CI_PROJECT_ID}-${CI_ENVIRONMENT_SLUG}.domain.com > environment_url.txt
     artifacts:
       paths: [environment_url.txt]
       when: always
     ```

     You can see an example of this in our
     [Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)
     file.
1. Select the **Validate** tab, then select **Validate pipeline**.
   The message **Simulation completed successfully** indicates the file is valid.
1. Select the **Edit** tab.
1. Optional. In **Commit message**, customize the commit message.
1. Select **Commit changes**.

Pipelines now include a DAST job.

The results are saved as a
[DAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast)
that you can later download and analyze. Due to implementation limitations, we
always take the latest DAST artifact available. Behind the scenes, the
[GitLab DAST Docker image](https://gitlab.com/security-products/dast)
is used to run the tests on the specified URL and scan it for possible
vulnerabilities.

#### Configure DAST using the UI

In this method you select options in the UI. Based on your selections, a code
snippet is created that you paste into the `.gitlab-ci.yml` file.

To configure DAST using the UI:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Enable DAST** or
   **Configure DAST**.
1. Select the desired **Scanner profile**, or select **Create scanner profile** and save a
   scanner profile. For more details, see [scanner profiles](../dast/on-demand_scan.md#scanner-profile).
1. Select the desired **Site profile**, or select **Create site profile** and save a site
   profile. For more details, see [site profiles](../dast/on-demand_scan.md#site-profile).
1. Select **Generate code snippet**. A modal opens with the YAML snippet corresponding to the
   options you selected.
1. Do one of the following:
   1. To copy the snippet to your clipboard, select **Copy code only**.
   1. To add the snippet to your project's `.gitlab-ci.yml` file, select
      **Copy code and open `.gitlab-ci.yml` file**. The pipeline editor opens.
      1. Paste the snippet into the `.gitlab-ci.yml` file.
      1. Select the **Validate** tab, then select **Validate pipeline**.
         The message **Simulation completed successfully** indicates the file is valid.
      1. Select the **Edit** tab.
      1. Optional. In **Commit message**, customize the commit message.
      1. Select **Commit changes**.

Pipelines now include a DAST job.

### API scan

- The [API security testing analyzer](../api_security_testing/index.md) is used for scanning web APIs. Web API technologies such as GraphQL, REST, and SOAP are supported.

### URL scan

A URL scan allows you to specify which parts of a website are scanned by DAST.

#### Define the URLs to scan

URLs to scan can be specified by either of the following methods:

- Use `DAST_PATHS_FILE` CI/CD variable to specify the name of a file containing the paths.
- Use `DAST_PATHS` variable to list the paths.

##### Use `DAST_PATHS_FILE` CI/CD variable

To define the URLs to scan in a file, create a plain text file with one path per line.

```plaintext
page1.html
/page2.html
category/shoes/page1.html
```

To scan the URLs in that file, set the CI/CD variable `DAST_PATHS_FILE` to the path of that file.
The file can be checked into the project repository or generated as an artifact by a job that
runs before DAST.

By default, DAST scans do not clone the project repository. Instruct the DAST job to clone
the project by setting `GIT_STRATEGY` to fetch. Give a file path relative to `CI_PROJECT_DIR` to `DAST_PATHS_FILE`.

```yaml
include:
  - template: DAST.gitlab-ci.yml

variables:
  GIT_STRATEGY: fetch
  DAST_PATHS_FILE: url_file.txt  # url_file.txt lives in the root directory of the project
  DAST_BROWSER_SCAN: "true" # use the browser-based GitLab DAST crawler
```

##### Use `DAST_PATHS` CI/CD variable

To specify the paths to scan in a CI/CD variable, add a comma-separated list of the paths to the `DAST_PATHS`
variable. You can only scan paths of a single host.

```yaml
include:
  - template: DAST.gitlab-ci.yml

variables:
  DAST_PATHS: "/page1.html,/category1/page1.html,/page3.html"
  DAST_BROWSER_SCAN: "true" # use the browser-based GitLab DAST crawler
```

When using `DAST_PATHS` and `DAST_PATHS_FILE`, note the following:

- `DAST_WEBSITE` must be defined when using either `DAST_PATHS_FILE` or `DAST_PATHS`. The paths listed in either use `DAST_WEBSITE` to build the URLs to scan
- Spidering is disabled when `DAST_PATHS` or `DAST_PATHS_FILE` are defined
- `DAST_PATHS_FILE` and `DAST_PATHS` cannot be used together
- The `DAST_PATHS` variable has a limit of about 130 kb. If you have a list or paths
  greater than this, use `DAST_PATHS_FILE`.

#### Full Scan

To perform a [full scan](#full-scan) on the listed paths, use the `DAST_FULL_SCAN_ENABLED` CI/CD variable.

## Authentication

The proxy-based analyzer uses the browser-based analyzer to authenticate a user prior to a scan. See [Authentication](authentication.md) for configuration instructions.

## Customize DAST settings

You can customize the behavior of DAST using both CI/CD variables and command-line options. Use of CI/CD
variables overrides the values contained in the DAST template.

### Customize DAST using CI/CD variables

The DAST settings can be changed through CI/CD variables by using the
[`variables`](../../../ci/yaml/index.md#variables) parameter in `.gitlab-ci.yml`. For details of
all DAST CI/CD variables, read [Available CI/CD variables](#available-cicd-variables).

For example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

variables:
  DAST_WEBSITE: https://example.com
  DAST_SPIDER_MINS: 120
  DAST_BROWSER_SCAN: "true" # use the browser-based GitLab DAST crawler
```

Because the template is [evaluated before](../../../ci/yaml/index.md#include) the pipeline
configuration, the last mention of the variable takes precedence.

#### Enable or disable rules

A complete list of the rules that DAST uses to scan for vulnerabilities can be
found in the [ZAP documentation](https://www.zaproxy.org/docs/alerts/).

`DAST_EXCLUDE_RULES` disables the rules with the given IDs.

`DAST_ONLY_INCLUDE_RULES` restricts the set of rules used in the scan to
those with the given IDs.

`DAST_EXCLUDE_RULES` and `DAST_ONLY_INCLUDE_RULES` are mutually exclusive and a
DAST scan with both configured exits with an error.

By default, several rules are disabled because they either take a long time to
run or frequently generate false positives. The complete list of disabled rules
can be found in [`exclude_rules.yml`](https://gitlab.com/gitlab-org/security-products/dast/-/blob/main/src/config/exclude_rules.yml).

The lists for `DAST_EXCLUDE_RULES` and `DAST_ONLY_INCLUDE_RULES` **must** be enclosed in double
quotes (`"`), otherwise they are interpreted as numeric values.

#### Hide sensitive information

HTTP request and response headers may contain sensitive information, including cookies and
authorization credentials. By default, the following headers are masked:

- `Authorization`.
- `Proxy-Authorization`.
- `Set-Cookie` (values only).
- `Cookie` (values only).

Using the [`DAST_MASK_HTTP_HEADERS` CI/CD variable](#available-cicd-variables), you can list the
headers whose values you want masked. For details on how to mask headers, see
[Customizing the DAST settings](#customize-dast-settings).

#### Use Mutual TLS

Mutual TLS allows a target application server to verify that requests are from a known source. Browser-based scans do not support Mutual TLS.

**Requirements**

- Base64-encoded PKCS12 certificate
- Password of the base64-encoded PKCS12 certificate

To enable Mutual TLS:

1. If the PKCS12 certificate is not already base64-encoded, convert it to base64 encoding. For security reasons, we recommend encoding the certificate locally, **not** using a web-hosted conversion service. For example, to encode the certificate on either macOS or Linux:

   ```shell
   base64 <path-to-pkcs12-certificate-file>
   ```

1. Create a [masked variable](../../../ci/variables/index.md) named `DAST_PKCS12_CERTIFICATE_BASE64` and store the base64-encoded PKCS12 certificate's value in that variable.
1. Create a masked variable `DAST_PKCS12_PASSWORD` and store the PKCS12 certificate's password in that variable.

#### Available CI/CD variables

These CI/CD variables are specific to DAST. They can be used to customize the behavior of DAST to your requirements.
For authentication CI/CD variables, see [Authentication](authentication.md).

WARNING:
All customization of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

| CI/CD variable                                  | Type          | Description                   |
|:------------------------------------------------|:--------------|:------------------------------|
| `DAST_ADVERTISE_SCAN`                           | boolean       | Set to `true` to add a `Via` header to every request sent, advertising that the request was sent as part of a GitLab DAST scan. |
| `DAST_AGGREGATE_VULNERABILITIES`                | boolean       | Vulnerability aggregation is set to `true` by default. To disable this feature and see each vulnerability individually set to `false`. |
| `DAST_ALLOWED_HOSTS`                            | Comma-separated list of strings | Hostnames included in this variable are considered in scope when crawled. By default the `DAST_WEBSITE` hostname is included in the allowed hosts list. Headers set using `DAST_REQUEST_HEADERS` are added to every request made to these hostnames. Example, `site.com,another.com`. |
| `DAST_API_HOST_OVERRIDE` <sup>1</sup>           | string        | **{warning}** **[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)** in GitLab 16.0. Replaced by [API security testing scan](../api_security_testing/configuration/variables.md). |
| `DAST_API_SPECIFICATION` <sup>1</sup>           | URL or string | **{warning}** **[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)** in GitLab 16.0. Replaced by [API security testing scan](../api_security_testing/configuration/variables.md). |
| `DAST_AUTO_UPDATE_ADDONS`                       | boolean       | ZAP add-ons are pinned to specific versions in the DAST Docker image. Set to `true` to download the latest versions when the scan starts. Default: `false`. |
| `DAST_DEBUG` <sup>1</sup>                       | boolean       | Enable debug message output. Default: `false`. |
| `DAST_EXCLUDE_RULES`                            | string        | Set to a comma-separated list of Vulnerability Rule IDs to exclude them from running during the scan. Rule IDs are numbers and can be found from the DAST log or on the [ZAP project](https://www.zaproxy.org/docs/alerts/). For example, `HTTP Parameter Override` has a rule ID of `10026`. Cannot be used when `DAST_ONLY_INCLUDE_RULES` is set. **Note:** In earlier versions of GitLab the excluded rules were executed but vulnerabilities they generated were suppressed. |
| `DAST_EXCLUDE_URLS` <sup>1</sup>                | URLs          | The URLs to skip during the authenticated scan; comma-separated. Regular expression syntax can be used to match multiple URLs. For example, `.*` matches an arbitrary character sequence. Example, `http://example.com/sign-out`. |
| `DAST_FULL_SCAN_ENABLED` <sup>1</sup>           | boolean       | Set to `true` to run a [ZAP Full Scan](https://github.com/zaproxy/zaproxy/wiki/ZAP-Full-Scan) instead of a [ZAP Baseline Scan](https://github.com/zaproxy/zaproxy/wiki/ZAP-Baseline-Scan). Default: `false` |
| `DAST_HTML_REPORT`                              | string        | **{warning}** **[Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/384340)** in GitLab 15.7. The filename of the HTML report written at the end of a scan. |
| `DAST_INCLUDE_ALPHA_VULNERABILITIES`            | boolean       | Set to `true` to include alpha passive and active scan rules. Default: `false`. |
| `DAST_MARKDOWN_REPORT`                          | string        | **{warning}** **[Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/384340)** in GitLab 15.7. The filename of the Markdown report written at the end of a scan. |
| `DAST_MASK_HTTP_HEADERS`                        | string        | Comma-separated list of request and response headers to be masked. Must contain **all** headers to be masked. Refer to [list of headers that are masked by default](#hide-sensitive-information). |
| `DAST_MAX_URLS_PER_VULNERABILITY`               | number        | The maximum number of URLs reported for a single vulnerability. `DAST_MAX_URLS_PER_VULNERABILITY` is set to `50` by default. To list all the URLs set to `0`. |
| `DAST_ONLY_INCLUDE_RULES`                       | string        | Set to a comma-separated list of Vulnerability Rule IDs to configure the scan to run only them. Rule IDs are numbers and can be found from the DAST log or on the [ZAP project](https://www.zaproxy.org/docs/alerts/). Cannot be used when `DAST_EXCLUDE_RULES` is set.  |
| `DAST_PATHS`                                    | string        | Set to a comma-separated list of URLs for DAST to scan. For example, `/page1.html,/category1/page3.html,/page2.html`.  |
| `DAST_PATHS_FILE`                               | string        | The file path containing the paths within `DAST_WEBSITE` to scan. The file must be plain text with one path per line.  |
| `DAST_PKCS12_CERTIFICATE_BASE64`                | string        | The PKCS12 certificate used for sites that require Mutual TLS. Must be encoded as base64 text. |
| `DAST_PKCS12_PASSWORD`                          | string        | The password of the certificate used in `DAST_PKCS12_CERTIFICATE_BASE64`. |
| `DAST_REQUEST_HEADERS` <sup>1</sup>             | string        | Set to a comma-separated list of request header names and values. Headers are added to every request made by DAST. For example, `Cache-control: no-cache,User-Agent: DAST/1.0` |
| `DAST_SKIP_TARGET_CHECK`                        | boolean       | Set to `true` to prevent DAST from checking that the target is available before scanning. Default: `false`.  |
| `DAST_SPIDER_MINS` <sup>1</sup>                 | number        | The maximum duration of the spider scan in minutes. Set to `0` for unlimited. Default: One minute, or unlimited when the scan is a full scan. |
| `DAST_SPIDER_START_AT_HOST`                     | boolean       | Set to `false` to prevent DAST from resetting the target to its host before scanning. When `true`, non-host targets `http://test.site/some_path` is reset to `http://test.site` before scan. Default: `false`. |
| `DAST_TARGET_AVAILABILITY_TIMEOUT` <sup>1</sup> | number        | Time limit in seconds to wait for target availability. |
| `DAST_USE_AJAX_SPIDER` <sup>1</sup>             | boolean       | Set to `true` to use the AJAX spider in addition to the traditional spider, useful for crawling sites that require JavaScript. Default: `false`.  |
| `DAST_XML_REPORT`                               | string        | **{warning}** **[Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/384340)** in GitLab 15.7. The filename of the XML report written at the end of a scan.  |
| `DAST_WEBSITE` <sup>1</sup>                     | URL           | The URL of the website to scan. |
| `DAST_ZAP_CLI_OPTIONS`                          | string        | **{warning}** **[Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)** in GitLab 15.7. ZAP server command-line options. For example, `-Xmx3072m` would set the Java maximum memory allocation pool size. |
| `DAST_ZAP_LOG_CONFIGURATION`                    | string        | **{warning}** **[Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)** in GitLab 15.7. Set to a semicolon-separated list of additional log4j properties for the ZAP Server. Example: `logger.httpsender.name=org.parosproxy.paros.network.HttpSender;logger.httpsender.level=debug;logger.sitemap.name=org.parosproxy.paros.model.SiteMap;logger.sitemap.level=debug;` |
| `SECURE_ANALYZERS_PREFIX`                       | URL           | Set the Docker registry base address from which to download the analyzer. |

1. Available to an on-demand DAST scan.

### Customize DAST using command-line options

Not all DAST configuration is available via CI/CD variables. To find out all
possible options, run the following configuration.
Available command-line options are printed to the job log:

```yaml
include:
  template: DAST.gitlab-ci.yml

dast:
  script:
    - /analyze --help
```

You must then overwrite the `script` command to pass in the appropriate
argument. For example, vulnerability definitions in alpha can be included with
`-a`. The following configuration includes those definitions:

```yaml
include:
  template: DAST.gitlab-ci.yml

dast:
  script:
    - export DAST_WEBSITE=${DAST_WEBSITE:-$(cat environment_url.txt)}
    - /analyze -a -t $DAST_WEBSITE
```

### Custom ZAProxy configuration

The ZAProxy server contains many [useful configurable values](https://gitlab.com/gitlab-org/gitlab/-/issues/36437#note_245801885).
Many key/values for `-config` remain undocumented, but there is an untested list of
[possible keys](https://gitlab.com/gitlab-org/gitlab/-/issues/36437#note_244981023).
These options are not supported by DAST, and may break the DAST scan
when used. An example of how to rewrite the Authorization header value with `TOKEN` follows:

```yaml
include:
  template: DAST.gitlab-ci.yml

variables:
  DAST_ZAP_CLI_OPTIONS: "-config replacer.full_list(0).description=auth -config replacer.full_list(0).enabled=true -config replacer.full_list(0).matchtype=REQ_HEADER -config replacer.full_list(0).matchstr=Authorization -config replacer.full_list(0).regex=false -config replacer.full_list(0).replacement=TOKEN"
```

### Bleeding-edge vulnerability definitions

ZAP first creates rules in the `alpha` class. After a testing period with
the community, they are promoted to `beta`. DAST uses `beta` definitions by
default. To request `alpha` definitions, use the
`DAST_INCLUDE_ALPHA_VULNERABILITIES` CI/CD variable as shown in the
following configuration:

```yaml
include:
  template: DAST.gitlab-ci.yml

variables:
  DAST_INCLUDE_ALPHA_VULNERABILITIES: "true"
```

### Cloning the project's repository

The DAST job does not require the project's repository to be present when running, so by default
[`GIT_STRATEGY`](../../../ci/runners/configure_runners.md#git-strategy) is set to `none`.

## Reports

The DAST tool outputs a `gl-dast-report.json` report file containing details of the scan and its results.
This file is included in the job's artifacts. JSON is the default format, but
you can output the report in Markdown, HTML, and XML formats. To specify an alternative
format, use a [CI/CD variable](#available-cicd-variables).

For details of the report's schema, see the [schema for DAST reports](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dast-report-format.json). Example reports can be found in the
[DAST repository](https://gitlab.com/gitlab-org/security-products/dast/-/tree/main/test/end-to-end/expect).

WARNING:
The JSON report artifacts are not a public API of DAST and their format is expected to change in the
future.

## Troubleshooting

### `unable to get local issuer certificate` when trying to validate a site profile

The use of self-signed certificates is not supported and may cause the job to fail with an error message: `unable to get local issuer certificate`. For more information, see [issue 416670](https://gitlab.com/gitlab-org/gitlab/-/issues/416670).

<!--- end_remove -->
