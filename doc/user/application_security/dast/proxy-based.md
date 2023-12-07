---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# DAST proxy-based analyzer **(ULTIMATE ALL)**

The DAST proxy-based analyzer can be added to your [GitLab CI/CD](../../../ci/index.md) pipeline.
This helps you discover vulnerabilities in web applications that do not use JavaScript heavily. For applications that do,
see the [DAST browser-based analyzer](browser_based.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video walkthrough, see [How to set up Dynamic Application Security Testing (DAST) with GitLab](https://youtu.be/EiFE1QrUQfk?si=6rpgwgUpalw3ByiV).

WARNING:
Do not run DAST scans against a production server. Not only can it perform *any* function that
a user can, such as clicking buttons or submitting forms, but it may also trigger bugs, leading to modification or loss of production data. Only run DAST scans against a test server.

The analyzer uses the [Software Security Project Zed Attack Proxy](https://www.zaproxy.org/) (ZAP) to scan in two different ways:

- Passive scan only (default). DAST executes
  [ZAP's Baseline Scan](https://www.zaproxy.org/docs/docker/baseline-scan/) and doesn't
  actively attack your application.
- Passive and active (or full) scan. DAST can be [configured](#full-scan) to also perform an active scan
  to attack your application and produce a more extensive security report. It can be very
  useful when combined with [Review Apps](../../../ci/review_apps/index.md).

## Templates

> - The DAST latest template was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/254325) in GitLab 13.8.
> - All DAST templates were [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62597) to DAST_VERSION: 2 in GitLab 14.0.
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
1. Copy and paste the following to the bottom of the `.gitlab-ci.yml` file.

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
   scanner profile. For more details, see [scanner profiles](#scanner-profile).
1. Select the desired **Site profile**, or select **Create site profile** and save a site
   profile. For more details, see [site profiles](#site-profile).
1. Select **Generate code snippet**. A modal opens with the YAML snippet corresponding to the
   options you selected.
1. Do one of the following:
   1. To copy the snippet to your clipboard, select **Copy code only**.
   1. To add the snippet to your project's `.gitlab-ci.yml` file, select
      **Copy code and open `.gitlab-ci.yml` file**. The Pipeline Editor opens.
      1. Paste the snippet into the `.gitlab-ci.yml` file.
      1. Select the **Validate** tab, then select **Validate pipeline**.
         The message **Simulation completed successfully** indicates the file is valid.
      1. Select the **Edit** tab.
      1. Optional. In **Commit message**, customize the commit message.
      1. Select **Commit changes**.

Pipelines now include a DAST job.

### API scan

- The [DAST API analyzer](../dast_api/index.md) is used for scanning web APIs. Web API technologies such as GraphQL, REST, and SOAP are supported.

### URL scan

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214120) in GitLab 13.4.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/273141) in GitLab 13.11.

A URL scan allows you to specify which parts of a website are scanned by DAST.

#### Define the URLs to scan

URLs to scan can be specified by either of the following methods:

- Use `DAST_PATHS_FILE` CI/CD variable to specify the name of a file containing the paths.
- Use `DAST_PATHS` variable to list the paths.

##### Use `DAST_PATHS_FILE` CI/CD variable

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/258825) in GitLab 13.6.

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214120) in GitLab 13.4.

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

WARNING:
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/index.md#only--except)
is no longer supported. You must use [`rules`](../../../ci/yaml/index.md#rules) instead.

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36332) in GitLab 13.1.

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299596) in GitLab 14.8.

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
| `DAST_API_HOST_OVERRIDE` <sup>1</sup>           | string        | **{warning}** **[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)** in GitLab 16.0. Replaced by [DAST API scan](../dast_api/index.md#available-cicd-variables). |
| `DAST_API_SPECIFICATION` <sup>1</sup>           | URL or string | **{warning}** **[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)** in GitLab 16.0. Replaced by [DAST API scan](../dast_api/index.md#available-cicd-variables). |
| `DAST_AUTH_EXCLUDE_URLS`                        | URLs          | **{warning}** **[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/289959)** in GitLab 14.0. Replaced by `DAST_EXCLUDE_URLS`. The URLs to skip during the authenticated scan; comma-separated. Regular expression syntax can be used to match multiple URLs. For example, `.*` matches an arbitrary character sequence. |
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

## On-demand scans

> - Auditing for DAST profile management [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217872) in GitLab 14.1.
> - Scheduled on-demand DAST scans [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328749) in GitLab 14.3 [with a flag](../../../administration/feature_flags.md) named  `dast_on_demand_scans_scheduler`. Disabled by default.
> - Scheduled on-demand DAST scans [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/328749) in GitLab 14.5. Feature flag `dast_on_demand_scans_scheduler` removed.
> - Runner tags selection [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111499) in GitLab 16.3.

WARNING:
On-demand scans are not available when GitLab is running in FIPS mode.

An on-demand DAST scan runs outside the DevOps life cycle. Changes in your repository don't trigger
the scan. You must either start it manually, or schedule it to run. For on-demand DAST scans,
a [site profile](#site-profile) defines **what** is to be scanned, and a
[scanner profile](#scanner-profile) defines **how** the application is to be scanned.

An on-demand scan can be run in active or passive mode:

- **Passive mode**: The default mode, which runs a ZAP Baseline Scan.
- **Active mode**: Runs a ZAP Full Scan which is potentially harmful to the site being scanned. To
  minimize the risk of accidental damage, running an active scan requires a
  [validated site profile](#site-profile-validation).

### View on-demand DAST scans

To view on-demand scans:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > On-demand scans**.

On-demand scans are grouped by their status. The scan library contains all available on-demand
scans.

### Run an on-demand DAST scan

Prerequisites:

- You must have permission to run an on-demand DAST scan against a protected branch. The default
  branch is automatically protected. For more information, see
  [Pipeline security on protected branches](../../../ci/pipelines/index.md#pipeline-security-on-protected-branches).

To run an existing on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the scan's row, select **Run scan**.

   If the branch saved in the scan no longer exists, you must:

   1. [Edit the scan](#edit-an-on-demand-scan).
   1. Select a new branch.
   1. Save the edited scan.

The on-demand DAST scan runs, and the project's dashboard shows the results.

#### Create an on-demand scan

Create an on-demand scan to:

- Run it immediately.
- Save it to be run in the future.
- Schedule it to be run at a specified schedule.

To create an on-demand DAST scan:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > On-demand scans**.
1. Select **New scan**.
1. Complete the **Scan name** and **Description** fields.
1. In the **Branch** dropdown list, select the desired branch.
1. Optional. Select the runner tags.
1. Select **Select scanner profile** or **Change scanner profile** to open the drawer, and either:
   - Select a scanner profile from the drawer, **or**
   - Select **New profile**, create a [scanner profile](#scanner-profile), then select **Save profile**.
1. Select **Select site profile** or **Change site profile** to open the drawer, and either:
   - Select a site profile from the **Site profile library** drawer, or
   - Select **New profile**, create a [site profile](#site-profile), then select **Save profile**.
1. To run the on-demand scan:

   - Immediately, select **Save and run scan**.
   - In the future, select **Save scan**.
   - On a schedule:

     - Turn on the **Enable scan schedule** toggle.
     - Complete the schedule fields.
     - Select **Save scan**.

The on-demand DAST scan runs as specified and the project's dashboard shows the results.

### View details of an on-demand scan

To view details of an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** (**{ellipsis_v}**), then select **Edit**.

### Edit an on-demand scan

To edit an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** (**{ellipsis_v}**), then select **Edit**.
1. Edit the saved scan's details.
1. Select **Save scan**.

### Delete an on-demand scan

To delete an on-demand scan:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > On-demand scans**.
1. Select the **Scan library** tab.
1. In the saved scan's row select **More actions** (**{ellipsis_v}**), then select **Delete**.
1. On the confirmation dialog, select **Delete**.

## Site profile

> - Site profile features, scan method and file URL, were [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345837) in GitLab 15.6.
> - GraphQL endpoint path feature was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378692) in GitLab 15.7.

A site profile defines the attributes and configuration details of the deployed application,
website, or API to be scanned by DAST. A site profile can be referenced in `.gitlab-ci.yml` and
on-demand scans.

A site profile contains:

- **Profile name**: A name you assign to the site to be scanned. While a site profile is referenced
  in either `.gitlab-ci.yml` or an on-demand scan, it **cannot** be renamed.
- **Site type**: The type of target to be scanned, either website or API scan.
- **Target URL**: The URL that DAST runs against.
- **Excluded URLs**: A comma-separated list of URLs to exclude from the scan.
- **Request headers**: A comma-separated list of HTTP request headers, including names and values. These headers are added to every request made by DAST.
- **Authentication**:
  - **Authenticated URL**: The URL of the page containing the sign-in HTML form on the target website. The username and password are submitted with the login form to create an authenticated scan.
  - **Username**: The username used to authenticate to the website.
  - **Password**: The password used to authenticate to the website.
  - **Username form field**: The name of username field at the sign-in HTML form.
  - **Password form field**: The name of password field at the sign-in HTML form.
  - **Submit form field**: The `id` or `name` of the element that when selected submits the sign-in HTML form.

- **Scan method**: A type of method to perform API testing. The supported methods are OpenAPI, Postman Collections, HTTP Archive (HAR), or GraphQL.
  - **GraphQL endpoint path**: The path to the GraphQL endpoint. This path is concatenated with the target URL to provide the URI for the scan to test. The GraphQL endpoint must support introspection queries.
  - **File URL**: The URL of the OpenAPI, Postman Collection, or HTTP Archive file.

When an API site type is selected, a host override is used to ensure the API being scanned is on the same host as the target. This is done to reduce the risk of running an active scan against the wrong API.

When configured, request headers and password fields are encrypted using [`aes-256-gcm`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) before being stored in the database.
This data can only be read and decrypted with a valid secrets file.

### Site profile validation

> Meta tag validation [introduced](https://gitlab.com/groups/gitlab-org/-/epics/6460) in GitLab 14.2.

Site profile validation reduces the risk of running an active scan against the wrong website. A site
must be validated before an active scan can run against it. Each of the site validation methods are
equivalent in functionality, so use whichever is most suitable:

- **Text file validation**: Requires a text file be uploaded to the target site. The text file is
  allocated a name and content that is unique to the project. The validation process checks the
  file's content.
- **Header validation**: Requires the header `Gitlab-On-Demand-DAST` be added to the target site,
  with a value unique to the project. The validation process checks that the header is present, and
  checks its value.
- **Meta tag validation**: Requires the meta tag named `gitlab-dast-validation` be added to the
  target site, with a value unique to the project. Make sure it's added to the `<head>` section of
  the page. The validation process checks that the meta tag is present, and checks its value.

### Create a site profile

To create a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select **New > Site profile**.
1. Complete the fields then select **Save profile**.

The site profile is saved, for use in an on-demand scan.

### Edit a site profile

NOTE:
If a site profile is linked to a security policy, you cannot edit the profile from this page. See
[Scan execution policies](../policies/scan-execution-policies.md) for more information.

NOTE:
If a site profile's Target URL or Authenticated URL is updated, the request headers and password fields associated with that profile are cleared.

When a validated site profile's file, header, or meta tag is edited, the site's
[validation status](#site-profile-validation) is revoked.

To edit a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row select the **More actions** (**{ellipsis_v}**) menu, then select **Edit**.
1. Edit the fields then select **Save profile**.

### Delete a site profile

NOTE:
If a site profile is linked to a security policy, a user cannot delete the profile from this page.
See [Scan execution policies](../policies/scan-execution-policies.md) for more information.

To delete a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row, select the **More actions** (**{ellipsis_v}**) menu, then select **Delete**.
1. Select **Delete** to confirm the deletion.

### Validate a site profile

Validating a site is required to run an active scan.

Prerequisites:

- A runner must be available in the project to run a validation job.
- The GitLab server's certificate must be trusted and must not use a self-signed certificate.

To validate a site profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row, select **Validate**.
1. Select the validation method.
   1. For **Text file validation**:
      1. Download the validation file listed in **Step 2**.
      1. Upload the validation file to the host, to the location in **Step 3** or any location you
         prefer.
      1. If required, edit the file location in **Step 3**.
      1. Select **Validate**.
   1. For **Header validation**:
      1. Select the clipboard icon in **Step 2**.
      1. Edit the header of the site to validate, and paste the clipboard content.
      1. Select the input field in **Step 3** and enter the location of the header.
      1. Select **Validate**.
   1. For **Meta tag validation**:
      1. Select the clipboard icon in **Step 2**.
      1. Edit the content of the site to validate, and paste the clipboard content.
      1. Select the input field in **Step 3** and enter the location of the meta tag.
      1. Select **Validate**.

The site is validated and an active scan can run against it. A site profile's validation status is
revoked only when it's revoked manually, or its file, header, or meta tag is edited.

### Retry a failed validation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322609) in GitLab 14.3.
> - [Deployed behind the `dast_failed_site_validations` flag](../../../administration/feature_flags.md), enabled by default.
> - [Feature flag `dast_failed_site_validations` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/323961) in GitLab 14.4.

Failed site validation attempts are listed on the **Site profiles** tab of the **Manage profiles**
page.

To retry a site profile's failed validation:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Site Profiles** tab.
1. In the profile's row, select **Retry validation**.

### Revoke a site profile's validation status

WARNING:
When a site profile's validation status is revoked, all site profiles that share the same URL also
have their validation status revoked.

To revoke a site profile's validation status:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Beside the validated profile, select **Revoke validation**.

The site profile's validation status is revoked.

### Validated site profile headers

The following are code samples of how you can provide the required site profile header in your
application.

#### Ruby on Rails example for on-demand scan

Here's how you can add a custom header in a Ruby on Rails application:

```ruby
class DastWebsiteTargetController < ActionController::Base
  def dast_website_target
    response.headers['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'
    head :ok
  end
end
```

#### Django example for on-demand scan

Here's how you can add a
[custom header in Django](https://docs.djangoproject.com/en/2.2/ref/request-response/#setting-header-fields):

```python
class DastWebsiteTargetView(View):
    def head(self, *args, **kwargs):
      response = HttpResponse()
      response['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'

      return response
```

#### Node (with Express) example for on-demand scan

Here's how you can add a
[custom header in Node (with Express)](https://expressjs.com/en/5x/api.html#res.append):

```javascript
app.get('/dast-website-target', function(req, res) {
  res.append('Gitlab-On-Demand-DAST', '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c')
  res.send('Respond to DAST ping')
})
```

## Scanner profile

A scanner profile defines the configuration details of a security scanner. A scanner profile can be
referenced in `.gitlab-ci.yml` and on-demand scans.

A scanner profile contains:

- **Profile name:** A name you give the scanner profile. For example, "Spider_15". While a scanner
  profile is referenced in either `.gitlab-ci.yml` or an on-demand scan, it **cannot** be renamed.
- **Scan mode:** A passive scan monitors all HTTP messages (requests and responses) sent to the target. An active scan attacks the target to find potential vulnerabilities.
- **Spider timeout:** The maximum number of minutes allowed for the spider to traverse the site.
- **Target timeout:** The maximum number of seconds DAST waits for the site to be available before
  starting the scan.
- **AJAX spider:** Run the AJAX spider, in addition to the traditional spider, to crawl the target site.
- **Debug messages:** Include debug messages in the DAST console output.

### Create a scanner profile

To create a scanner profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select **New > Scanner profile**.
1. Complete the form. For details of each field, see [Scanner profile](#scanner-profile).
1. Select **Save profile**.

### Edit a scanner profile

NOTE:
If a scanner profile is linked to a security policy, you cannot edit the profile from this page.
For more information, see [Scan execution policies](../policies/scan-execution-policies.md).

To edit a scanner profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Scanner profiles** tab.
1. In the scanner's row, select the **More actions** (**{ellipsis_v}**) menu, then select **Edit**.
1. Edit the form.
1. Select **Save profile**.

### Delete a scanner profile

NOTE:
If a scanner profile is linked to a security policy, a user cannot delete the profile from this
page. For more information, see [Scan execution policies](../policies/scan-execution-policies.md).

To delete a scanner profile:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Security configuration**.
1. In the **Dynamic Application Security Testing (DAST)** section, select **Manage profiles**.
1. Select the **Scanner profiles** tab.
1. In the scanner's row, select the **More actions** (**{ellipsis_v}**) menu, then select **Delete**.
1. Select **Delete**.

## Auditing

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217872) in GitLab 14.1.

The creation, updating, and deletion of DAST profiles, DAST scanner profiles,
and DAST site profiles are included in the [audit log](../../../administration/audit_events.md).

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
