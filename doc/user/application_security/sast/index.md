---
type: reference, howto
---

# Static Application Security Testing (SAST) **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/3775) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3.

NOTE: **4 of the top 6 attacks were application based.**
Download our whitepaper,
["A Seismic Shift in Application Security"](https://about.gitlab.com/resources/whitepaper-seismic-shift-application-security/)
to learn how to protect your organization.

## Overview

If you're using [GitLab CI/CD](../../../ci/README.md), you can analyze your source code for known
vulnerabilities using Static Application Security Testing (SAST).

You can take advantage of SAST by doing one of the following:

- [Including the SAST template](#configuration) in your existing `.gitlab-ci.yml` file.
- Implicitly using [Auto SAST](../../../topics/autodevops/stages.md#auto-sast-ultimate) provided by
  [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the SAST report, compares the found vulnerabilities between the
source and target branches, and shows the information right on the merge request.

![SAST Widget](img/sast_v12_9.png)

The results are sorted by the priority of the vulnerability:

1. Critical
1. High
1. Medium
1. Low
1. Unknown
1. Everything else

NOTE: **Note:**
A pipeline consists of multiple jobs, including SAST and DAST scanning. If any job fails to finish for any reason, the security dashboard won't show SAST scanner output. For example, if the SAST job finishes but the DAST job fails, the security dashboard won't show SAST results. The analyzer will output an [exit code](../../../development/integrations/secure.md#exit-code) on failure.

## Use cases

- Your code has a potentially dangerous attribute in a class, or unsafe code
  that can lead to unintended code execution.
- Your application is vulnerable to cross-site scripting (XSS) attacks that can
  be leveraged to unauthorized access to session data.

## Requirements

To run a SAST job, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html#running-privileged-containers-for-the-runners)
executor running in privileged mode. If you're using the shared Runners on GitLab.com,
this is enabled by default.

Privileged mode is not necessary if you've [disabled Docker in Docker
for SAST](#disabling-docker-in-docker-for-sast).

CAUTION: **Caution:** Our SAST jobs currently expect a Linux container type. Windows containers are not yet supported.

CAUTION: **Caution:**
If you use your own Runners, make sure the Docker version installed
is **not** `19.03.0`. See [troubleshooting information](#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

## Supported languages and frameworks

The following table shows which languages, package managers and frameworks are supported and which tools are used.

| Language (package managers) / framework                                     | Scan tool                                                                              | Introduced in GitLab Version |
|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------|------------------------------|
| .NET                                                                        | [Security Code Scan](https://security-code-scan.github.io)                             | 11.0                         |
| Any                                                                         | [Gitleaks](https://github.com/zricethezav/gitleaks) and [TruffleHog](https://github.com/dxa4481/truffleHog) | 11.9    |
| Apex (Salesforce)                                                           | [PMD](https://pmd.github.io/pmd/index.html)                                            | 12.1                         |
| C/C++                                                                       | [Flawfinder](https://dwheeler.com/flawfinder/)                                         | 10.7                         |
| Elixir (Phoenix)                                                            | [Sobelow](https://github.com/nccgroup/sobelow)                                         | 11.10                        |
| Go                                                                          | [Gosec](https://github.com/securego/gosec)                                             | 10.7                         |
| Groovy ([Ant](https://ant.apache.org/), [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) and [SBT](https://www.scala-sbt.org/)) | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 11.3 (Gradle) & 11.9 (Ant, Maven, SBT) |
| Java ([Ant](https://ant.apache.org/), [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) and [SBT](https://www.scala-sbt.org/)) | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 10.6 (Maven), 10.8 (Gradle) & 11.9 (Ant, SBT) |
| JavaScript                                                                  | [ESLint security plugin](https://github.com/nodesecurity/eslint-plugin-security)       | 11.8                         |
| Kubernetes manifests                                                        | [Kubesec](https://github.com/controlplaneio/kubesec)                                   | 12.6                         |
| Node.js                                                                     | [NodeJsScan](https://github.com/ajinabraham/NodeJsScan)                                | 11.1                         |
| PHP                                                                         | [phpcs-security-audit](https://github.com/FloeDesignTechnologies/phpcs-security-audit) | 10.8                         |
| Python ([pip](https://pip.pypa.io/en/stable/))                              | [bandit](https://github.com/PyCQA/bandit)                                              | 10.3                         |
| React                                                                       | [ESLint react plugin](https://github.com/yannickcr/eslint-plugin-react)                | 12.5                         |
| Ruby on Rails                                                               | [brakeman](https://brakemanscanner.org)                                                | 10.3                         |
| Scala ([Ant](https://ant.apache.org/), [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) and [SBT](https://www.scala-sbt.org/)) | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 11.0 (SBT) & 11.9 (Ant, Gradle, Maven) |
| TypeScript                                                                  | [`tslint-config-security`](https://github.com/webschik/tslint-config-security/) | 11.9 |

NOTE: **Note:**
The Java analyzers can also be used for variants like the
[Gradle wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html),
[Grails](https://grails.org/) and the [Maven wrapper](https://github.com/takari/maven-wrapper).

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

NOTE: **Note:**
You don't have to configure SAST manually as shown in this section if you're using [Auto SAST](../../../topics/autodevops/stages.md#auto-sast-ultimate)
provided by [Auto DevOps](../../../topics/autodevops/index.md).

For GitLab 11.9 and later, to enable SAST you must [include](../../../ci/yaml/README.md#includetemplate)
the [`SAST.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)
provided as a part of your GitLab installation. For GitLab versions earlier than 11.9, you
can copy and use the job as defined that template.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: SAST.gitlab-ci.yml
```

The included template will create a `sast` job in your CI/CD pipeline and scan
your project's source code for possible vulnerabilities.

The results will be saved as a
[SAST report artifact](../../../ci/pipelines/job_artifacts.md#artifactsreportssast-ultimate)
that you can later download and analyze. Due to implementation limitations, we
always take the latest SAST artifact available. Behind the scenes, the
[GitLab SAST Docker image](https://gitlab.com/gitlab-org/security-products/sast)
is used to detect the languages or frameworks used, and in turn runs the matching scan tools.

### Customizing the SAST settings

The SAST settings can be changed through [environment variables](#available-variables)
by using the
[`variables`](../../../ci/yaml/README.md#variables) parameter in `.gitlab-ci.yml`.
In the following example, we include the SAST template and at the same time we
set the `SAST_GOSEC_LEVEL` variable to `2`:

```yaml
include:
  - template: SAST.gitlab-ci.yml

variables:
  SAST_GOSEC_LEVEL: 2
```

Because the template is [evaluated before](../../../ci/yaml/README.md#include)
the pipeline configuration, the last mention of the variable takes precedence.

### Overriding the SAST template

CAUTION: **Deprecation:**
Beginning in GitLab 13.0, the use of [`only` and `except`](../../../ci/yaml/README.md#onlyexcept-basic)
is no longer supported. When overriding the template, you must use [`rules`](../../../ci/yaml/README.md#rules) instead.

If you want to override the job definition (for example, change properties like
`variables` or `dependencies`), you need to declare a `sast` job after the
template inclusion and specify any additional keys under it. For example:

```yaml
include:
  - template: SAST.gitlab-ci.yml

sast:
  variables:
    CI_DEBUG_TRACE: "true"
```

### Using environment variables to pass credentials for private repositories

Some analyzers require downloading the project's dependencies in order to
perform the analysis. In turn, such dependencies may live in private Git
repositories and thus require credentials like username and password to download them.
Depending on the analyzer, such credentials can be provided to
it via [custom environment variables](#custom-environment-variables).

#### Using a variable to pass username and password to a private Maven repository

If your private Maven repository requires login credentials,
you can use the `MAVEN_CLI_OPTS` environment variable.

Read more on [how to use private Maven repositories](../index.md#using-private-maven-repos).

### Disabling Docker in Docker for SAST

You can avoid the need for Docker in Docker by running the individual analyzers.
This does not require running the executor in privileged mode. For example:

```yaml
include:
  - template: SAST.gitlab-ci.yml

variables:
  SAST_DISABLE_DIND: "true"
```

This will create individual `<analyzer-name>-sast` jobs for each analyzer that runs in your CI/CD pipeline.

By removing Docker-in-Docker (DIND), GitLab relies on [Linguist](https://github.com/github/linguist)
to start relevant analyzers depending on the detected repository language(s) instead of the
[orchestrator](https://gitlab.com/gitlab-org/security-products/dependency-scanning/). However, there
are some differences in the way repository languages are detected between DIND and non-DIND. You can
observe these differences by checking both Linguist and the common library. For instance, Linguist
looks for `*.java` files to spin up the [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)
image, while orchestrator only looks for the existence of `pom.xml`, `build.xml`, `gradlew`,
`grailsw`, or `mvnw`. GitLab uses Linguist to detect new file types in the default branch.
When introducing files or dependencies for a new language or package manager, the
corresponding scans won't be triggered in the MR, and will only run on the default branch once the
MR is merged. This will be addressed by [#211702](https://gitlab.com/gitlab-org/gitlab/-/issues/211702).

NOTE: **Note:**
With the current language detection logic, any new languages or frameworks introduced within the
context of a merge request don't trigger a corresponding scan. These scans only occur once the code
is committed to the default branch.

#### Enabling Kubesec analyzer

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/12752) in GitLab Ultimate 12.6.

When [Docker in Docker is disabled](#disabling-docker-in-docker-for-sast),
you will need to set `SCAN_KUBERNETES_MANIFESTS` to `"true"` to enable the
Kubesec analyzer. In `.gitlab-ci.yml`, define:

```yaml
include:
  - template: SAST.gitlab-ci.yml

variables:
  SAST_DISABLE_DIND: "true"
  SCAN_KUBERNETES_MANIFESTS: "true"
```

#### Pre-compilation

If your project requires custom build configurations, it can be preferable to avoid
compilation during your SAST execution and instead pass all job artifacts from an
earlier stage within the pipeline. This is the current strategy when requiring
a `before_script` execution to prepare your scan job.

To pass your project's dependencies as artifacts, the dependencies must be included
in the project's working directory and specified using the `artifacts:path` configuration.
If all dependencies are present, the `-compile=false` flag can be provided to the
analyzer and compilation will be skipped:

```yaml
image: maven:3.6-jdk-8-alpine

stages:
 - build
 - test

include:
  - template: SAST.gitlab-ci.yml

variables:
  SAST_DISABLE_DIND: "true"

build:
  stage: build
  script:
    - mvn package -Dmaven.repo.local=./.m2/repository
  artifacts:
    paths:
      - .m2/
      - target/

spotbugs-sast:
  dependencies:
    - build
  script:
    - /analyzer run -compile=false
  variables:
    MAVEN_REPO_PATH: ./.m2/repository
  artifacts:
    reports:
      sast: gl-sast-report.json
```

NOTE: **Note:**
The path to the vendored directory must be specified explicitly to allow
the analyzer to recognize the compiled artifacts. This configuration can vary per
analyzer but in the case of Java above, `MAVEN_REPO_PATH` can be used.
See [Analyzer settings](#analyzer-settings) for the complete list of available options.

### Available variables

SAST can be [configured](#customizing-the-sast-settings) using environment variables.

#### Custom Certificate Authority

To trust a custom Certificate Authority, set the `ADDITIONAL_CA_CERT_BUNDLE` variable to the bundle
of CA certs that you want to trust within the SAST environment.

#### Docker images

The following are Docker image-related variables.

| Environment variable         | Description                                                                                                                                                                                                              |
|------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SAST_ANALYZER_IMAGE_PREFIX` | Override the name of the Docker registry providing the default images (proxy). Read more about [customizing analyzers](analyzers.md).                                                                                    |
| `SAST_ANALYZER_IMAGE_TAG`    | **DEPRECATED:** Override the Docker tag of the default images. Read more about [customizing analyzers](analyzers.md).                                                                                                                    |
| `SAST_DEFAULT_ANALYZERS`     | Override the names of default images. Read more about [customizing analyzers](analyzers.md).                                                                                                                             |
| `SAST_DISABLE_DIND`          | Disable Docker in Docker and run analyzers [individually](#disabling-docker-in-docker-for-sast).                                                                                                                         |

#### Vulnerability filters

Some analyzers make it possible to filter out vulnerabilities under a given threshold.

| Environment variable    | Default value | Description |
|-------------------------|---------------|-------------|
| `SAST_EXCLUDED_PATHS`         | -   | Exclude vulnerabilities from output based on the paths. This is a comma-separated list of patterns. Patterns can be globs, or file or folder paths (for example, `doc,spec` ). Parent directories will also match patterns. |
| `SAST_BANDIT_EXCLUDED_PATHS`  | -   | comma-separated list of paths to exclude from scan. Uses Python's [`fnmatch` syntax](https://docs.python.org/2/library/fnmatch.html) |
| `SAST_BRAKEMAN_LEVEL`   |         1 | Ignore Brakeman vulnerabilities under given confidence level. Integer, 1=Low 3=High. |
| `SAST_FLAWFINDER_LEVEL` |         1 | Ignore Flawfinder vulnerabilities under given risk level. Integer, 0=No risk, 5=High risk. |
| `SAST_GITLEAKS_ENTROPY_LEVEL` | 8.0 | Minimum entropy for secret detection. Float, 0.0 = low, 8.0 = high. |
| `SAST_GOSEC_LEVEL`      |         0 | Ignore Gosec vulnerabilities under given confidence level. Integer, 0=Undefined, 1=Low, 2=Medium, 3=High. |
| `SAST_GITLEAKS_COMMIT_FROM` | -     | The commit a Gitleaks scan starts at. |
| `SAST_GITLEAKS_COMMIT_TO` | -       | The commit a Gitleaks scan ends at. |
| `SAST_GITLEAKS_HISTORIC_SCAN` | false | Flag to enable a historic Gitleaks scan. |

#### Docker-in-Docker orchestrator

The following variables configure the Docker-in-Docker orchestrator.

| Environment variable                     | Default value | Description |
|------------------------------------------|---------------|-------------|
| `SAST_ANALYZER_IMAGES`                   |         |  Comma-separated list of custom images. Default images are still enabled. Read more about [customizing analyzers](analyzers.md). Not available when [Docker-in-Docker is disabled](#disabling-docker-in-docker-for-sast). |
| `SAST_PULL_ANALYZER_IMAGES`              |       1 | Pull the images from the Docker registry (set to 0 to disable). Read more about [customizing analyzers](analyzers.md). Not available when [Docker-in-Docker is disabled](#disabling-docker-in-docker-for-sast).          |
| `SAST_DOCKER_CLIENT_NEGOTIATION_TIMEOUT` |      2m | Time limit for Docker client negotiation. Timeouts are parsed using Go's [`ParseDuration`](https://golang.org/pkg/time/#ParseDuration). Valid time units are `ns`, `us` (or `µs`), `ms`, `s`, `m`, `h`. For example, `300ms`, `1.5h` or `2h45m`. |
| `SAST_PULL_ANALYZER_IMAGE_TIMEOUT`       |      5m | Time limit when pulling the image of an analyzer. Timeouts are parsed using Go's [`ParseDuration`](https://golang.org/pkg/time/#ParseDuration). Valid time units are `ns`, `us` (or `µs`), `ms`, `s`, `m`, `h`. For example, `300ms`, `1.5h` or `2h45m`. |
| `SAST_RUN_ANALYZER_TIMEOUT`              |     20m | Time limit when running an analyzer. Timeouts are parsed using Go's [`ParseDuration`](https://golang.org/pkg/time/#ParseDuration). Valid time units are `ns`, `us` (or `µs`), `ms`, `s`, `m`, `h`. For example, `300ms`, `1.5h` or `2h45m`.|

NOTE: **Note:**
Timeout variables are not applicable for setups with [disabled Docker In Docker](index.md#disabling-docker-in-docker-for-sast).

#### Analyzer settings

Some analyzers can be customized with environment variables.

| Environment variable        | Analyzer | Description |
|-----------------------------|----------|-------------|
| `SCAN_KUBERNETES_MANIFESTS` | Kubesec  | Set to `"true"` to scan Kubernetes manifests when [Docker in Docker](#disabling-docker-in-docker-for-sast) is disabled. |
| `ANT_HOME`                  | SpotBugs | The `ANT_HOME` environment variable. |
| `ANT_PATH`                  | SpotBugs | Path to the `ant` executable. |
| `GRADLE_PATH`               | SpotBugs | Path to the `gradle` executable. |
| `JAVA_OPTS`                 | SpotBugs | Additional arguments for the `java` executable. |
| `JAVA_PATH`                 | SpotBugs | Path to the `java` executable. |
| `SAST_JAVA_VERSION`         | SpotBugs | Which Java version to use. Supported versions are `8` and `11`. Defaults to `8`. |
| `MAVEN_CLI_OPTS`            | SpotBugs | Additional arguments for the `mvn` or `mvnw` executable. |
| `MAVEN_PATH`                | SpotBugs | Path to the `mvn` executable. |
| `MAVEN_REPO_PATH`           | SpotBugs | Path to the Maven local repository (shortcut for the `maven.repo.local` property). |
| `SBT_PATH`                  | SpotBugs | Path to the `sbt` executable. |
| `FAIL_NEVER`                | SpotBugs | Set to `1` to ignore compilation failure. |

#### Custom environment variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18193) in GitLab Ultimate 12.5.

In addition to the aforementioned SAST configuration variables,
all [custom environment variables](../../../ci/variables/README.md#custom-environment-variables) are propagated
to the underlying SAST analyzer images if
[the SAST vendored template](#configuration) is used.

CAUTION: **Caution:**
Variables having names starting with these prefixes will **not** be propagated to the SAST Docker container and/or
analyzer containers: `DOCKER_`, `CI`, `GITLAB_`, `FF_`, `HOME`, `PWD`, `OLDPWD`, `PATH`, `SHLVL`, `HOSTNAME`.

## Reports JSON format

CAUTION: **Caution:**
The JSON report artifacts are not a public API of SAST and their format may change in the future.

The SAST tool emits a JSON report file. Here is an example of the report structure with all important parts of
it highlighted:

```json-doc
{
  "version": "2.0",
  "vulnerabilities": [
    {
      "id": "9e96e0ab-23da-4d7d-a09e-0acbaa5e83ca",
      "category": "sast",
      "name": "Predictable pseudorandom number generator",
      "message": "Predictable pseudorandom number generator",
      "description": "The use of java.util.Random is predictable",
      "severity": "Medium",
      "confidence": "Medium",
      "scanner": {
        "id": "find_sec_bugs",
        "name": "Find Security Bugs"
      },
      "location": {
        "file": "groovy/src/main/groovy/com/gitlab/security_products/tests/App.groovy",
        "start_line": 47,
        "end_line": 47,
        "class": "com.gitlab.security_products.tests.App",
        "method": "generateSecretToken2",
        "dependency": {
          "package": {}
        }
      },
      "identifiers": [
        {
          "type": "find_sec_bugs_type",
          "name": "Find Security Bugs-PREDICTABLE_RANDOM",
          "value": "PREDICTABLE_RANDOM",
          "url": "https://find-sec-bugs.github.io/bugs.htm#PREDICTABLE_RANDOM"
        },
        {
          "type": "cwe",
          "name": "CWE-330",
          "value": "330",
          "url": "https://cwe.mitre.org/data/definitions/330.html"
        }
      ]
    },
    {
      "id": "e6dbf91f-4c07-46f7-a365-0169489c27d1",
      "category": "sast",
      "message": "Probable insecure usage of temp file/directory.",
      "severity": "Medium",
      "confidence": "Medium",
      "scanner": {
        "id": "bandit",
        "name": "Bandit"
      },
      "location": {
        "file": "python/hardcoded/hardcoded-tmp.py",
        "start_line": 10,
        "end_line": 10,
        "dependency": {
          "package": {}
        }
      },
      "identifiers": [
        {
          "type": "bandit_test_id",
          "name": "Bandit Test ID B108",
          "value": "B108",
          "url": "https://docs.openstack.org/bandit/latest/plugins/b108_hardcoded_tmp_directory.html"
        }
      ]
    },
  ],
  "remediations": []
}
```

CAUTION: **Deprecation:**
Beginning with GitLab 12.9, SAST no longer reports `undefined` severity and confidence levels.

Here is the description of the report file structure nodes and their meaning. All fields are mandatory in
the report JSON unless stated otherwise. Presence of optional fields depends on the underlying analyzers being used.

| Report JSON node                        | Function |
|-----------------------------------------|----------|
| `version`                               | Report syntax version used to generate this JSON. |
| `vulnerabilities`                       | Array of vulnerability objects. |
| `vulnerabilities[].id`                  | Unique identifier of the vulnerability. |
| `vulnerabilities[].category`            | Where this vulnerability belongs (such as SAST, Dependency Scanning). For SAST, it will always be `sast`. |
| `vulnerabilities[].name`                | Name of the vulnerability. Must not include the occurrence's specific information. Optional. |
| `vulnerabilities[].message`             | A short text that describes the vulnerability, it may include the occurrence's specific information. Optional. |
| `vulnerabilities[].description`         | A long text that describes the vulnerability. Optional. |
| `vulnerabilities[].cve`                 | (**DEPRECATED - use `vulnerabilities[].id` instead**) A fingerprint string value that represents a concrete occurrence of the vulnerability. It's used to determine whether two vulnerability occurrences are same or different. May not be 100% accurate. **This is NOT a [CVE](https://cve.mitre.org/)**.                                                                                                                                      |
| `vulnerabilities[].severity`            | How much the vulnerability impacts the software. Possible values: `Info`, `Unknown`, `Low`, `Medium`, `High`, `Critical`. |
| `vulnerabilities[].confidence`          | How reliable the vulnerability's assessment is. Possible values: `Ignore`, `Unknown`, `Experimental`, `Low`, `Medium`, `High`, `Confirmed`. |
| `vulnerabilities[].solution`            | Explanation of how to fix the vulnerability. Optional. |
| `vulnerabilities[].scanner`             | A node that describes the analyzer used to find this vulnerability. |
| `vulnerabilities[].scanner.id`          | ID of the scanner as a snake_case string. |
| `vulnerabilities[].scanner.name`        | Name of the scanner, for display purposes. |
| `vulnerabilities[].location`            | A node that tells where the vulnerability is located. |
| `vulnerabilities[].location.file`       | Path to the file where the vulnerability is located. Optional. |
| `vulnerabilities[].location.start_line` | The first line of the code affected by the vulnerability. Optional. |
| `vulnerabilities[].location.end_line`   | The last line of the code affected by the vulnerability. Optional. |
| `vulnerabilities[].location.class`      | If specified, provides the name of the class where the vulnerability is located. Optional. |
| `vulnerabilities[].location.method`     | If specified, provides the name of the method where the vulnerability is located. Optional. |
| `vulnerabilities[].identifiers`         | An ordered array of references that identify a vulnerability on internal or external databases. |
| `vulnerabilities[].identifiers[].type`  | Type of the identifier. Possible values: common identifier types (among `cve`, `cwe`, `osvdb`, and `usn`) or analyzer-dependent ones (like `bandit_test_id` for [Bandit analyzer](https://wiki.openstack.org/wiki/Security/Projects/Bandit)). |
| `vulnerabilities[].identifiers[].name`  | Name of the identifier for display purposes. |
| `vulnerabilities[].identifiers[].value` | Value of the identifier for matching purposes. |
| `vulnerabilities[].identifiers[].url`   | URL to identifier's documentation. Optional. |

## Secret detection

GitLab is also able to detect secrets and credentials that have been unintentionally pushed to the
repository, such as an API key that allows write access to third-party deployment
environments.

This check is performed by a specific analyzer during the `sast` job. It runs regardless of the programming
language of your app, and you don't need to change anything to your
CI/CD configuration file to turn it on. Results are available in the SAST report.

GitLab currently includes [Gitleaks](https://github.com/zricethezav/gitleaks) and [TruffleHog](https://github.com/dxa4481/truffleHog) checks.

NOTE: **Note:**
The secrets analyzer will ignore "Password in URL" vulnerabilities if the password begins
with a dollar sign (`$`) as this likely indicates the password being used is an environment
variable. For example, `https://username:$password@example.com/path/to/repo` won't be
detected, whereas `https://username:password@example.com/path/to/repo` would be detected.

## Security Dashboard

The Security Dashboard is a good place to get an overview of all the security
vulnerabilities in your groups, projects and pipelines. Read more about the
[Security Dashboard](../security_dashboard/index.md).

## Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

## Vulnerabilities database update

For more information about the vulnerabilities database update, check the
[maintenance table](../index.md#maintenance-and-update-of-the-vulnerabilities-database).

## Running SAST in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the SAST job to
run successfully. For more information, see [Offline environments](../offline_deployments/index.md).

### Requirements for offline SAST

To use SAST in an offline environment, you need:

- To [disable Docker-In-Docker](#disabling-docker-in-docker-for-sast).
- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- Docker Container Registry with locally available copies of SAST [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers) images.

NOTE: **Note:**
GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the Runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. GitLab Runner's [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

### Make GitLab SAST analyzer images available inside your Docker registry

For SAST with all [supported languages and frameworks](#supported-languages-and-frameworks),
import the following default SAST analyzer images from `registry.gitlab.com` into your
[local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/gitlab-org/security-products/analyzers/bandit:2
registry.gitlab.com/gitlab-org/security-products/analyzers/brakeman:2
registry.gitlab.com/gitlab-org/security-products/analyzers/eslint:2
registry.gitlab.com/gitlab-org/security-products/analyzers/flawfinder:2
registry.gitlab.com/gitlab-org/security-products/analyzers/go-ast-scanner:2
registry.gitlab.com/gitlab-org/security-products/analyzers/gosec:2
registry.gitlab.com/gitlab-org/security-products/analyzers/kubesec:2
registry.gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan:2
registry.gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit:2
registry.gitlab.com/gitlab-org/security-products/analyzers/pmd-apex:2
registry.gitlab.com/gitlab-org/security-products/analyzers/secrets:2
registry.gitlab.com/gitlab-org/security-products/analyzers/security-code-scan:2
registry.gitlab.com/gitlab-org/security-products/analyzers/sobelow:2
registry.gitlab.com/gitlab-org/security-products/analyzers/spotbugs:2
registry.gitlab.com/gitlab-org/security-products/analyzers/tslint:2
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Please consult your IT staff to find an accepted and approved
process by which external resources can be imported or temporarily accessed. Note that these scanners are [updated periodically](../index.md#maintenance-and-update-of-the-vulnerabilities-database)
with new definitions, so consider if you're able to make periodic updates yourself.

For details on saving and transporting Docker images as a file, see Docker's documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

### Set SAST CI job variables to use local SAST analyzers

Add the following configuration to your `.gitlab-ci.yml` file. You must replace
`SAST_ANALYZER_IMAGE_PREFIX` to refer to your local Docker container registry:

  ```yaml
include:
  - template: SAST.gitlab-ci.yml

variables:
  SAST_ANALYZER_IMAGE_PREFIX: "localhost:5000/analyzers"
  SAST_DISABLE_DIND: "true"
  ```

The SAST job should now use local copies of the SAST analyzers to scan your code and generate
security reports without requiring internet access.

## Troubleshooting

### Error response from daemon: error processing tar file: docker-tar: relocation error

This error occurs when the Docker version used to run the SAST job is `19.03.0`.
Consider updating to Docker `19.03.1` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/issues/13830#note_211354992 "Current SAST container fails").
