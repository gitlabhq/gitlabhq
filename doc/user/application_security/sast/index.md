---
type: reference, howto
---

# Static Application Security Testing (SAST) **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/3775)
in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3.

NOTE: **4 of the top 6 attacks were application based.**
Download our whitepaper,
["A Seismic Shift in Application Security"](https://about.gitlab.com/resources/whitepaper-seismic-shift-application-security/)
to learn how to protect your organization.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can analyze your source code for known
vulnerabilities using Static Application Security Testing (SAST).

You can take advantage of SAST by either [including the CI job](#configuration) in
your existing `.gitlab-ci.yml` file or by implicitly using
[Auto SAST](../../../topics/autodevops/index.md#auto-sast-ultimate)
that is provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab checks the SAST report, compares the found vulnerabilities between the
source and target branches, and shows the information right on the merge request.

![SAST Widget](img/sast.png)

The results are sorted by the priority of the vulnerability:

1. Critical
1. High
1. Medium
1. Low
1. Unknown
1. Everything else

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
for SAST](#disabling-docker-in-docker-for-sast)

CAUTION: **Caution:**
If you use your own Runners, make sure that the Docker version you have installed
is **not** `19.03.00`. See [troubleshooting information](#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

## Supported languages and frameworks

The following table shows which languages, package managers and frameworks are supported and which tools are used.

| Language (package managers) / framework                                     | Scan tool                                                                              | Introduced in GitLab Version |
|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------|------------------------------|
| .NET                                                                        | [Security Code Scan](https://security-code-scan.github.io)                             | 11.0                         |
| Any                                                                         | [Gitleaks](https://github.com/zricethezav/gitleaks) and [TruffleHog](https://github.com/dxa4481/truffleHog) | 11.9    |
| Apex (Salesforce)                                                           | [pmd](https://pmd.github.io/pmd/index.html)                                            | 12.1                         |
| C/C++                                                                       | [Flawfinder](https://dwheeler.com/flawfinder/)                                         | 10.7                         |
| Elixir (Phoenix)                                                            | [Sobelow](https://github.com/nccgroup/sobelow)                                         | 11.10                        |
| Go                                                                          | [Gosec](https://github.com/securego/gosec)                                             | 10.7                         |
| Groovy ([Ant](https://ant.apache.org/), [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) and [SBT](https://www.scala-sbt.org/)) | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 11.3 (Gradle) & 11.9 (Ant, Maven, SBT) |
| Java ([Ant](https://ant.apache.org/), [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) and [SBT](https://www.scala-sbt.org/)) | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 10.6 (Maven), 10.8 (Gradle) & 11.9 (Ant, SBT) |
| JavaScript                                                                  | [ESLint security plugin](https://github.com/nodesecurity/eslint-plugin-security)       | 11.8                         |
| Node.js                                                                     | [NodeJsScan](https://github.com/ajinabraham/NodeJsScan)                                | 11.1                         |
| PHP                                                                         | [phpcs-security-audit](https://github.com/FloeDesignTechnologies/phpcs-security-audit) | 10.8                         |
| Python ([pip](https://pip.pypa.io/en/stable/))                              | [bandit](https://github.com/PyCQA/bandit)                                              | 10.3                         |
| React                                                                       | [ESLint react plugin](https://github.com/yannickcr/eslint-plugin-react)                | 12.5                         |
| Ruby on Rails                                                               | [brakeman](https://brakemanscanner.org)                                                | 10.3                         |
| Scala ([Ant](https://ant.apache.org/), [Gradle](https://gradle.org/), [Maven](https://maven.apache.org/) and [SBT](https://www.scala-sbt.org/)) | [SpotBugs](https://spotbugs.github.io/) with the [find-sec-bugs](https://find-sec-bugs.github.io/) plugin | 11.0 (SBT) & 11.9 (Ant, Gradle, Maven) |
| TypeScript                                                                  | [TSLint config security](https://github.com/webschik/tslint-config-security/)          | 11.9                         |

NOTE: **Note:**
The Java analyzers can also be used for variants like the
[Gradle wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html),
[Grails](https://grails.org/) and the [Maven wrapper](https://github.com/takari/maven-wrapper).

## Configuration

For GitLab 11.9 and later, to enable SAST, you must
[include](../../../ci/yaml/README.md#includetemplate) the
[`SAST.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)
that's provided as a part of your GitLab installation.
For GitLab versions earlier than 11.9, you can copy and use the job as defined
that template.

Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  template: SAST.gitlab-ci.yml
```

The included template will create a `sast` job in your CI/CD pipeline and scan
your project's source code for possible vulnerabilities.

The results will be saved as a
[SAST report artifact](../../../ci/yaml/README.md#artifactsreportssast-ultimate)
that you can later download and analyze. Due to implementation limitations, we
always take the latest SAST artifact available. Behind the scenes, the
[GitLab SAST Docker image](https://gitlab.com/gitlab-org/security-products/sast)
is used to detect the languages/frameworks and in turn runs the matching scan tools.

### Customizing the SAST settings

The SAST settings can be changed through [environment variables](#available-variables)
by using the
[`variables`](../../../ci/yaml/README.md#variables) parameter in `.gitlab-ci.yml`.

In the following example, we include the SAST template and at the same time we
set the `SAST_GOSEC_LEVEL` variable to `2`:

```yaml
include:
  template: SAST.gitlab-ci.yml

variables:
  SAST_GOSEC_LEVEL: 2
```

Because the template is [evaluated before](../../../ci/yaml/README.md#include)
the pipeline configuration, the last mention of the variable will take precedence.

### Overriding the SAST template

If you want to override the job definition (for example, change properties like
`variables` or `dependencies`), you need to declare a `sast` job after the
template inclusion and specify any additional keys under it. For example:

```yaml
include:
  template: SAST.gitlab-ci.yml

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

If you have a private Apache Maven repository that requires login credentials,
you can use the `MAVEN_CLI_OPTS` [environment variable](#available-variables)
to pass a username and password. You can set it under your project's settings
so that your credentials aren't exposed in `.gitlab-ci.yml`.

If the username is `myuser` and the password is `verysecret` then you would
[set the following variable](../../../ci/variables/README.md#via-the-ui)
under your project's settings:

| Type | Key | Value |
| ---- | --- | ----- |
| Variable | `MAVEN_CLI_OPTS` | `-Drepository.password=verysecret -Drepository.user=myuser` |

### Disabling Docker in Docker for SAST

You can avoid the need for Docker in Docker by running the individual analyzers.
This does not require running the executor in privileged mode. For example:

```yaml
include:
  template: SAST.gitlab-ci.yml

variables:
  SAST_DISABLE_DIND: "true"
```

This will create individual `<analyzer-name>-sast` jobs for each analyzer that runs in your CI/CD pipeline.

### Available variables

SAST can be [configured](#customizing-the-sast-settings) using environment variables.

#### Docker images

The following are Docker image-related variables.

| Environment variable         | Description                                                                                                                                                                                                              |
|------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SAST_ANALYZER_IMAGES`       | Comma separated list of custom images. Default images are still enabled. Read more about [customizing analyzers](analyzers.md). Not available when [Docker in Docker is disabled](#disabling-docker-in-docker-for-sast). |
| `SAST_ANALYZER_IMAGE_PREFIX` | Override the name of the Docker registry providing the default images (proxy). Read more about [customizing analyzers](analyzers.md).                                                                                    |
| `SAST_ANALYZER_IMAGE_TAG`    | Override the Docker tag of the default images. Read more about [customizing analyzers](analyzers.md).                                                                                                                    |
| `SAST_DEFAULT_ANALYZERS`     | Override the names of default images. Read more about [customizing analyzers](analyzers.md).                                                                                                                             |
| `SAST_DISABLE_DIND`          | Disable Docker in Docker and run analyzers [individually](#disabling-docker-in-docker-for-sast).                                                                                                                         |
| `SAST_PULL_ANALYZER_IMAGES`  | Pull the images from the Docker registry (set to 0 to disable). Read more about [customizing analyzers](analyzers.md). Not available when [Docker in Docker is disabled](#disabling-docker-in-docker-for-sast).          |

#### Vulnerability filters

Some analyzers make it possible to filter out vulnerabilities under a given threshold.

| Environment variable | Default value | Description | Example usage |
|----------------------|---------------|-------------|---|
| `SAST_BANDIT_EXCLUDED_PATHS`  | -   | comma-separated list of paths to exclude from scan. Uses Python's [`fnmatch` syntax](https://docs.python.org/2/library/fnmatch.html) | |
| `SAST_BRAKEMAN_LEVEL`   |         1 | Ignore Brakeman vulnerabilities under given confidence level. Integer, 1=Low 3=High. | |
| `SAST_FLAWFINDER_LEVEL` |         1 | Ignore Flawfinder vulnerabilities under given risk level. Integer, 0=No risk, 5=High risk. | |
| `SAST_GITLEAKS_ENTROPY_LEVEL` | 8.0 | Minimum entropy for secret detection. Float, 0.0 = low, 8.0 = high. | |
| `SAST_GOSEC_LEVEL`      |         0 | Ignore gosec vulnerabilities under given confidence level. Integer, 0=Undefined, 1=Low, 2=Medium, 3=High. | |
| `SAST_EXCLUDED_PATHS`   |   -        | Exclude vulnerabilities from output based on the paths. This is a comma-separated list of patterns. Patterns can be globs, file or folder paths. Parent directories will also match patterns. | `SAST_EXCLUDED_PATHS=doc,spec` |

#### Timeouts

The following variables configure timeouts.

| Environment variable | Default value | Description |
|----------------------|---------------|-------------|
| `SAST_DOCKER_CLIENT_NEGOTIATION_TIMEOUT` |      2m | Time limit for Docker client negotiation. Timeouts are parsed using Go's [`ParseDuration`](https://golang.org/pkg/time/#ParseDuration). Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h". For example, "300ms", "1.5h" or "2h45m". |
| `SAST_PULL_ANALYZER_IMAGE_TIMEOUT`       |      5m | Time limit when pulling the image of an analyzer. Timeouts are parsed using Go's [`ParseDuration`](https://golang.org/pkg/time/#ParseDuration). Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h". For example, "300ms", "1.5h" or "2h45m". |
| `SAST_RUN_ANALYZER_TIMEOUT`              |     20m | Time limit when running an analyzer. Timeouts are parsed using Go's [`ParseDuration`](https://golang.org/pkg/time/#ParseDuration). Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h". For example, "300ms", "1.5h" or "2h45m".|

NOTE: **Note:**
Timeout variables are not applicable for setups with [disabled Docker In Docker](index.md#disabling-docker-in-docker-for-sast).

#### Analyzer settings

Some analyzers can be customized with environment variables.

| Environment variable    | Analyzer | Description |
|-------------------------|----------|----------|
| `ANT_HOME`              | spotbugs | The `ANT_HOME` environment variable. |
| `ANT_PATH`              | spotbugs | Path to the `ant` executable. |
| `GRADLE_PATH`           | spotbugs | Path to the `gradle` executable. |
| `JAVA_OPTS`             | spotbugs | Additional arguments for the `java` executable. |
| `JAVA_PATH`             | spotbugs | Path to the `java` executable. |
| `SAST_JAVA_VERSION`     | spotbugs | Which Java version to use. Supported versions are `8` and `11`. Defaults to `8`. |
| `MAVEN_CLI_OPTS`        | spotbugs | Additional arguments for the `mvn` or `mvnw` executable. |
| `MAVEN_PATH`            | spotbugs | Path to the `mvn` executable. |
| `MAVEN_REPO_PATH`       | spotbugs | Path to the Maven local repository (shortcut for the `maven.repo.local` property). |
| `SBT_PATH`              | spotbugs | Path to the `sbt` executable. |
| `FAIL_NEVER`            | spotbugs | Set to `1` to ignore compilation failure. |

#### Custom environment variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/18193) in GitLab Ultimate 12.5.

In addition to the aforementioned SAST configuration variables,
all [custom environment variables](../../../ci/variables/README.md#creating-a-custom-environment-variable) are propagated
to the underlying SAST analyzer images if
[the SAST vendored template](#configuration) is used.

CAUTION: **Caution:**
Variables having names starting with these prefixes will **not** be propagated to the SAST Docker container and/or
analyzer containers: `DOCKER_`, `CI`, `GITLAB_`, `FF_`, `HOME`, `PWD`, `OLDPWD`, `PATH`, `SHLVL`, `HOSTNAME`.

## Reports JSON format

CAUTION: **Caution:**
The JSON report artifacts are not a public API of SAST and their format may change in the future.

The SAST tool emits a JSON report report file. Here is an example of the report structure with all important parts of
it highlighted:

```json-doc
{
  "version": "2.0",
  "vulnerabilities": [
    {
      "category": "sast",
      "name": "Predictable pseudorandom number generator",
      "message": "Predictable pseudorandom number generator",
      "description": "The use of java.util.Random is predictable",
      "cve": "818bf5dacb291e15d9e6dc3c5ac32178:PREDICTABLE_RANDOM",
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
      "category": "sast",
      "message": "Probable insecure usage of temp file/directory.",
      "cve": "python/hardcoded/hardcoded-tmp.py:4ad6d4c40a8c263fc265f3384724014e0a4f8dd6200af83e51ff120420038031:B108",
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

Here is the description of the report file structure nodes and their meaning. All fields are mandatory to be present in
the report JSON unless stated otherwise. Presence of optional fields depends on the underlying analyzers being used.

| Report JSON node                        | Function |
|-----------------------------------------|----------|
| `version`                               | Report syntax version used to generate this JSON. |
| `vulnerabilities`                       | Array of vulnerability objects. |
| `vulnerabilities[].category`            | Where this vulnerability belongs (SAST, Dependency Scanning etc.). For SAST, it will always be `sast`. |
| `vulnerabilities[].name`                | Name of the vulnerability, this must not include the occurrence's specific information. Optional. |
| `vulnerabilities[].message`             | A short text that describes the vulnerability, it may include the occurrence's specific information. Optional. |
| `vulnerabilities[].description`         | A long text that describes the vulnerability. Optional. |
| `vulnerabilities[].cve`                 | A fingerprint string value that represents a concrete occurrence of the vulnerability. Is used to determine whether two vulnerability occurrences are same or different. May not be 100% accurate. **This is NOT a [CVE](https://cve.mitre.org/)**. |
| `vulnerabilities[].severity`            | How much the vulnerability impacts the software. Possible values: `Undefined` (an analyzer has not provided this info), `Info`, `Unknown`, `Low`, `Medium`, `High`, `Critical`. |
| `vulnerabilities[].confidence`          | How reliable the vulnerability's assessment is. Possible values: `Undefined` (an analyzer has not provided this info), `Ignore`, `Unknown`, `Experimental`, `Low`, `Medium`, `High`, `Confirmed`. |
| `vulnerabilities[].solution`            | Explanation of how to fix the vulnerability. Optional. |
| `vulnerabilities[].scanner`             | A node that describes the analyzer used to find this vulnerability. |
| `vulnerabilities[].scanner.id`          | Id of the scanner as a snake_case string. |
| `vulnerabilities[].scanner.name`        | Name of the scanner, for display purposes. |
| `vulnerabilities[].location`            | A node that tells where the vulnerability is located. |
| `vulnerabilities[].location.file`       | Path to the file where the vulnerability is located. Optional. |
| `vulnerabilities[].location.start_line` | The first line of the code affected by the vulnerability. Optional. |
| `vulnerabilities[].location.end_line`   | The last line of the code affected by the vulnerability. Optional. |
| `vulnerabilities[].location.class`      | If specified, provides the name of the class where the vulnerability is located. Optional. |
| `vulnerabilities[].location.method`     | If specified, provides the name of the method where the vulnerability is located. Optional. |
| `vulnerabilities[].identifiers`         | An ordered array of references that identify a vulnerability on internal or external DBs. |
| `vulnerabilities[].identifiers[].type`  | Type of the identifier. Possible values: common identifier types (among `cve`, `cwe`, `osvdb`, and `usn`) or analyzer-dependent ones (e.g., `bandit_test_id` for [Bandit analyzer](https://wiki.openstack.org/wiki/Security/Projects/Bandit)). |
| `vulnerabilities[].identifiers[].name`  | Name of the identifier for display purposes. |
| `vulnerabilities[].identifiers[].value` | Value of the identifier for matching purposes. |
| `vulnerabilities[].identifiers[].url`   | URL to identifier's documentation. Optional. |

## Secret detection

GitLab is also able to detect secrets and credentials that have been unintentionally pushed to the repository.
For example, an API key that allows write access to third-party deployment environments.

This check is performed by a specific analyzer during the `sast` job. It runs regardless of the programming
language of your app, and you don't need to change anything to your
CI/CD configuration file to turn it on. Results are available in the SAST report.

GitLab currently includes [Gitleaks](https://github.com/zricethezav/gitleaks) and [TruffleHog](https://github.com/dxa4481/truffleHog) checks.

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

## Troubleshooting

### Error response from daemon: error processing tar file: docker-tar: relocation error

This error occurs when the Docker version used to run the SAST job is `19.03.00`.
You are advised to update to Docker `19.03.01` or greater. Older versions are not
affected. Read more in
[this issue](https://gitlab.com/gitlab-org/gitlab/issues/13830#note_211354992 "Current SAST container fails").
